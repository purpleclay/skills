import { atom, memberOf, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { SpecView } from '../types'

// Shows the spec /refine is writing in a read-only pane beside the chat, and
// draws each save of it as one dim line in the chat instead of a diff.
// /refine never depends on it: where these hooks do not load, nothing changes.

const PANE = 'refine-spec'
const TICKET_SECTIONS = [
  'Goal',
  'Current behaviour',
  'Acceptance criteria',
  'Out of scope',
  'Constraints',
  'Sources',
]

const spec = atom({ plugin: 'purpleclay-skills', key: 'spec' } as const, null, {
  shape: 'spec-1',
})

// The one line each spec save draws as in the chat, by the call's tool_use_id.
const save = atom({ plugin: 'purpleclay-skills', key: 'save' } as const, null)

// The title and the ticket sections, without front matter, Open questions or
// the Interview log.
const ticketSections = (text: string): string => {
  const body = text.replace(/^---\n[\s\S]*?\n---\n/, '')
  const kept: string[] = []
  let isKept = false
  for (const line of body.split('\n')) {
    if (line.startsWith('# ')) isKept = true
    else if (line.startsWith('## '))
      isKept = TICKET_SECTIONS.includes(line.slice(3).trim())
    if (isKept) kept.push(line)
  }

  return kept.join('\n').trim()
}

type Section = { heading: string; lines: string[] }

const sectionsOf = (markdown: string) => {
  let title = ''
  const sections: Section[] = []
  for (const line of markdown.split('\n')) {
    if (line.startsWith('# ')) title = line.slice(2).trim()
    else if (line.startsWith('## '))
      sections.push({ heading: line.slice(3).trim(), lines: [] })
    else if (line.trim() !== '') sections.at(-1)?.lines.push(line.trim())
  }

  return { title, sections }
}

let refineDir: Promise<string | undefined> | undefined

const specsDir = ($: EngineInterface) =>
  (refineDir ??= $.process
    .run(['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'])
    .then(({ exitCode, stdout }) =>
      exitCode === 0 ? `${stdout.trim()}/refine/` : undefined,
    )
    .catch(() => undefined))

const isSpec = async ($: EngineInterface, path: string) => {
  const dir = await specsDir($)
  if (dir === undefined || !path.startsWith(dir)) return false
  const name = path.slice(dir.length)

  return name.endsWith('.md') && !name.includes('/')
}

// Each spec's last modification time, by path, or undefined when the specs
// can't be listed.
const specTimes = async ($: EngineInterface) => {
  const dir = await specsDir($)
  if (dir === undefined) return undefined
  const entries = await $.fs.list(dir).catch(() => undefined)

  return entries === undefined
    ? undefined
    : new Map(
        entries
          .filter(entry => entry.kind === 'file' && entry.name.endsWith('.md'))
          .map(entry => [`${dir}${entry.name}`, entry.mtimeMs]),
      )
}

// Names a save by the spec's last round, or as ready once it has no round left.
const saveLine = (text: string) => {
  const round = [...text.matchAll(/^### Round (\d+)/gm)].at(-1)?.[1]
  const isInProgress = /^---\n[\s\S]*?^state: in progress$[\s\S]*?\n---\n/m.test(text)

  return isInProgress && round !== undefined
    ? `Saved spec · round ${round}`
    : isInProgress
      ? 'Saved spec'
      : 'Saved spec · ready to publish'
}

async function showSaved($: EngineInterface, path: string, toolUseId: string) {
  if (!(await isSpec($, path))) return
  const text = await $.fs.read(path)
  await update($, memberOf(save, { requestId: toolUseId }), () => saveLine(text))
  await update($, spec, () => ({ path, markdown: ticketSections(text) }))
  await $.ui.open({ id: PANE, title: 'Spec', backgroundColor: 'transparent' })
}

// A save draws as one dim line, and its diff or output as nothing, unless the
// view draws every row in full (ctrl+o, --verbose) or the call failed, so its
// error stays in sight.
const savedLine = async (
  $: EngineInterface,
  e: { requestId: string; props: { isExpanded?: boolean; isErrored: boolean } },
) =>
  e.props.isExpanded === true || e.props.isErrored
    ? null
    : await read($, memberOf(save, e))

export const register: Register = on => {
  on('tool.call', { tool: 'Write' }, async ($, e, next) => {
    const ran = await next(e)
    if (ran.deny === undefined && ran.isError !== true)
      await showSaved($, e.file_path, e.tool_use_id).catch(() => undefined)

    return ran
  }).catch(($, e, next) => next(e))

  on('tool.call', { tool: 'Edit' }, async ($, e, next) => {
    const ran = await next(e)
    if (ran.deny === undefined && ran.isError !== true)
      await showSaved($, e.file_path, e.tool_use_id).catch(() => undefined)

    return ran
  }).catch(($, e, next) => next(e))

  // shortcut: only a Bash call is watched for the spec's deletion, as /to-ticket
  // deletes it with `rm`; watch other tools if it ever deletes it another way.
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    // /refine often saves the spec from the shell, with the path in a variable,
    // so compare the specs' modification times instead of reading the command.
    const before = await specTimes($)
    const ran = await next(e)
    const after = before === undefined ? undefined : await specTimes($)
    const [saved] = [...(after ?? [])]
      .filter(([path, time]) => before?.get(path) !== time)
      .sort(([, a], [, b]) => b - a)
    if (saved !== undefined)
      await showSaved($, saved[0], e.tool_use_id).catch(() => undefined)

    const shown = await read($, spec)
    if (shown !== null && !(await $.fs.exists(shown.path).catch(() => true))) {
      await update($, spec, () => null)
      await $.ui.close({ id: PANE })
    }

    return ran
  }).catch(($, e, next) => next(e))

  // shortcut: a save is known once its call returns, so a save's row draws in
  // full while it runs; mark Write and Edit calls by their path if that shows.
  on('ui.render', { component: 'ToolUse' }, async ($, e, next) => {
    const line = await savedLine($, e)
    if (line === null) return next(e)
    const { Text } = $.ui.resolve(e)

    return <Text color="inactive">{line}</Text>
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'ToolResult' }, async ($, e, next) => {
    if ((await savedLine($, e)) === null) return next(e)
    const { Box } = $.ui.resolve(e)

    return <Box />
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const shown = await read($, spec)
    if (shown === null) return <Text color="inactive">No spec saved yet.</Text>
    const { title, sections } = sectionsOf(shown.markdown)

    // Colours are Claude Code theme keys, so the pane follows the session's theme.
    const line = (text: string) => {
      if (text.startsWith('- [ ] '))
        return (
          <Box flexDirection="row">
            <Text color="subtle">☐ </Text>
            <Text color="text">{text.slice(6)}</Text>
          </Box>
        )
      const answer = /^- (.*): (yes|no)$/i.exec(text)
      const [, label, value = ''] = answer ?? []
      const isYes = value.toLowerCase() === 'yes'
      if (answer !== null)
        return (
          <Box flexDirection="row">
            <Text color="subtle">• </Text>
            <Text color="text">{label}: </Text>
            <Text
              bold={isYes}
              color={isYes ? 'warning' : 'subtle'}
            >
              {value}
            </Text>
          </Box>
        )
      if (text.startsWith('- '))
        return (
          <Box flexDirection="row">
            <Text color="subtle">• </Text>
            <Text color="text">{text.slice(2)}</Text>
          </Box>
        )

      return <Text color="text">{text}</Text>
    }

    return (
      <Box flexDirection="column">
        <Text bold color="claude">
          {title}
        </Text>
        <Text color="promptBorder">
          {'─'.repeat(Math.max(1, e.props.bodyColumns))}
        </Text>
        {sections.map(section => (
          <Box flexDirection="column" marginTop={1}>
            <Text bold color="suggestion">
              {section.heading}
            </Text>
            {section.lines.length === 0 ? (
              <Text color="inactive">Not settled yet</Text>
            ) : (
              section.lines.map(line)
            )}
          </Box>
        ))}
      </Box>
    )
  })
}
