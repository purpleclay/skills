import { expect, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

const GIT_DIR = '/repo/.git'
const SPEC = `${GIT_DIR}/refine/reject-big-uploads.md`

const SAVED = `---
state: in progress
---

# Reject uploads over the size limit

## Goal

Uploads over 10 MB fail fast.

## Current behaviour

## Acceptance criteria

- [ ] An 11 MB upload is rejected with 413

## Out of scope

## Constraints

- Public contract change: no
- Data migration: yes

## Sources

- https://example.com/upload-limits

## Open questions

- 3 · Size limit: should the limit be configurable?

## Interview

### Round 1

| Question | What I took from your reply |
| -------- | --------------------------- |
| 1 · Goal | Fail fast                   |
`

const PANE = {
  plugin: 'purpleclay-skills',
  component: 'Pane',
  requestId: 'refine-spec',
  props: {
    title: 'Spec',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

const engine = (on: On) => {
  const files = new Map<string, string>()
  // Each save gets a later modification time, as a real file system gives it.
  const mtimes = new Map<string, number>()
  let clock = 0
  const save = (path: string, content: string) => {
    files.set(path, content)
    mtimes.set(path, ++clock)
  }
  const panes = { opened: 0, closed: 0 }
  on('process.run', () => ({
    value: { exitCode: 0, stdout: `${GIT_DIR}\n`, stderr: '',
      isStdoutTruncated: false,
      isStderrTruncated: false,
    },
  }))
  on('fs.read', (_, e) => ({ value: files.get(e.path) ?? '' }))
  on('fs.exists', (_, e) => ({ value: files.has(e.path) }))
  on('fs.list', (_, e) => {
    const dir = e.path.endsWith('/') ? e.path : `${e.path}/`
    const value = [...files]
      .filter(([path]) => path.startsWith(dir) && !path.slice(dir.length).includes('/'))
      .map(([path, content]) => ({
        name: path.slice(dir.length),
        kind: 'file' as const,
        size: content.length,
        mtimeMs: mtimes.get(path) ?? 0,
        isLink: false,
      }))

    return { value }
  })
  on('ui.open', () => {
    panes.opened++
    return { value: { isPlaced: true } }
  })
  on('ui.close', () => {
    panes.closed++
    return { value: undefined }
  })
  on('tool.call', (_, e) => {
    if (e.tool === 'Write') save(e.file_path, e.content)
    if (e.tool === 'Bash' && e.command.startsWith('rm ')) {
      files.delete(e.command.slice(3))
      mtimes.delete(e.command.slice(3))
    }
    // A shell save, as /refine often writes the spec: cat > <path> <<'EOF' … EOF
    const shellSave =
      e.tool === 'Bash' ? /^cat > (\S+) <<'EOF'\n([\s\S]*)EOF$/.exec(e.command) : null
    if (shellSave !== null) save(shellSave[1] ?? '', shellSave[2] ?? '')
    return { result: {} }
  })

  return panes
}

const drawn = async ($: Engine) => {
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const texts = await ui.findAll({ type: 'Text' })
  await ui.unmount()

  return texts.map(node => node.text).join('\n')
}

test('a saved spec opens the pane with its ticket sections only', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })

  expect(panes.opened).toBe(1)
  const text = await drawn($)
  expect(text).toContain('Reject uploads over the size limit')
  expect(text).toContain('Acceptance criteria')
  expect(text).toContain('Constraints')
  expect(text).toContain('https://example.com/upload-limits')
  expect(text).not.toContain('state: in progress')
  expect(text).not.toContain('Open questions')
  expect(text).not.toContain('Interview')
  expect(text).not.toContain('configurable')
})

test('each save shows the spec as last saved', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({
    tool: 'Write',
    file_path: SPEC,
    content: SAVED.replace('10 MB', '20 MB'),
  })

  expect(await drawn($)).toContain('20 MB')
})

const catTo = (path: string, content: string) => `cat > ${path} <<'EOF'\n${content}EOF`

test('a spec saved through the shell opens the pane', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Bash', command: catTo(SPEC, SAVED) })

  expect(panes.opened).toBe(1)
  expect(await drawn($)).toContain('Reject uploads over the size limit')
})

test('a spec updated through the shell shows as last saved', async ($, on) => {
  engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({ tool: 'Bash', command: catTo(SPEC, SAVED.replace('10 MB', '20 MB')) })

  expect(await drawn($)).toContain('20 MB')
})

test('shell commands that change no spec leave the pane as it is', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Bash', command: 'git status' })
  await $.tool.call({ tool: 'Bash', command: catTo('/repo/notes.md', SAVED) })
  expect(panes.opened).toBe(0)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({ tool: 'Bash', command: `cat ${SPEC}` })
  expect(panes.opened).toBe(1)
})

test('files that are not specs leave the pane shut', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Write', file_path: '/repo/README.md', content: SAVED })
  await $.tool.call({
    tool: 'Write',
    file_path: `${GIT_DIR}/refine/reject-big-uploads.tickets.draft/1.md`,
    content: SAVED,
  })

  expect(panes.opened).toBe(0)
})

test('the pane stays open while the spec exists and closes once it is deleted', async ($, on) => {
  const panes = engine(on)

  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })
  await $.tool.call({ tool: 'Bash', command: 'gh issue create' })
  expect(panes.closed).toBe(0)

  await $.tool.call({ tool: 'Bash', command: `rm ${SPEC}` })
  expect(panes.closed).toBe(1)
})

test('the pane draws each part of the spec in Claude Code theme colours', async ($, on) => {
  engine(on)
  await $.tool.call({ tool: 'Write', file_path: SPEC, content: SAVED })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    const colour = async (text: RegExp) =>
      (await ui.find({ type: 'Text', text }))?.props.color

    expect(await colour(/^Reject uploads over the size limit$/)).toBe('claude')
    expect(await colour(/^Goal$/)).toBe('suggestion')
    expect(await colour(/^Not settled yet$/)).toBe('inactive')
    expect(await colour(/^☐ $/)).toBe('subtle')
    expect(await colour(/^An 11 MB upload is rejected with 413$/)).toBe('text')
    expect(await colour(/^yes$/)).toBe('warning')
    expect(await colour(/^no$/)).toBe('subtle')
    expect(await ui.findAll({ type: 'Text', text: /^Not settled yet$/ })).toHaveLength(2)
    await ui.unmount()
  }
})
