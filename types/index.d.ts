export type SpecView = { path: string; markdown: string }

declare module 'claude-code' {
  interface PluginState {
    'purpleclay-skills': {
      spec: Shaped<SpecView | null>
      save: StateFamily<string | null>
    }
  }
}
