# Frontend Design Playbook

This playbook contains deep guidance referenced by `SKILL.md`. Use it when the task needs detailed aesthetic rules or implementation examples.

## Aesthetic Archetypes

Choose one foundation archetype and avoid mixing styles unless there is a clear governing rule.

- **Editorial / Magazine**: Strong typographic hierarchy, generous whitespace, refined grids, serif display type, pull-quote moments.
- **Swiss / International**: Geometric precision, strict spacing systems, sans-serif dominance, asymmetric balance.
- **Brutalist / Raw**: Exposed structure, high contrast, visible borders, monospace usage, anti-decorative style.
- **Minimalist / Refined**: Restraint, micro-contrast, limited palette, precision spacing, subtle shadows.
- **Maximalist / Expressive**: Layered composition, bold colors, energetic motion, intentional visual density.
- **Retro-Futuristic**: Neon accents, CRT cues, scanlines, glow, terminal-inspired accents.
- **Organic / Natural**: Soft geometry, warm tones, tactile texture, rounded transitions, hand-made feel.
- **Industrial / Utilitarian**: Functional panel language, data-first layout density, minimal ornamentation.
- **Art Deco / Geometric**: Symmetry, metallic accents, ornamental geometry, decorative framing.
- **Lo-Fi / Zine**: Rough texture, collage, deliberate imperfection, halftone and duotone effects.

## Technical Deep Dive

### Typography

- Avoid default-looking stacks unless explicitly requested.
- Pair display and body families with visible contrast in weight, size, or character.
- Use fluid scaling with `clamp()` and tune rhythm:
  - Body text: line-height roughly `1.4` to `1.6`
  - Display text: line-height roughly `1.1` to `1.2`
- Use spacing and case intentionally for hierarchy, not only size.

### Color System

- Define tokenized colors: surface, text, muted, primary, accent, border.
- Add semantic state tokens (success, warning, error) where UX needs status communication.
- Prefer intentional distribution (for example dominant/supporting/accent) over evenly split palettes.
- Avoid default purple gradient motifs unless explicitly aligned with brand.

### Motion and Interaction

- Motion should communicate state, hierarchy, or affordance.
- Prefer eased timing (`cubic-bezier`) over generic linear transitions.
- Use staggered entrance timing when scanning order matters.
- For scroll reveals, prefer `IntersectionObserver` patterns over heavy timeline scripts.

### Spatial Composition

- Use Grid for 2D structure and Flexbox for linear alignment.
- Define spacing tokens (`--space-xs` through `--space-xl`) before component work.
- Use asymmetry and overlap intentionally to create focal tension.
- Treat whitespace as layout structure, not unused leftover area.

### Depth and Texture

- Use layered shadows for elevation levels (`--shadow-sm`, `--shadow-md`, `--shadow-lg`).
- Use texture overlays only when they reinforce the archetype.
- Gradients should be deliberate (radial/mesh/multi-stop) and tied to direction.
- Decorative borders, separators, and clipped shapes should support the core motif.

## Extended Anti-Pattern Rationale

- **Template smell**: repeated hero/cards/testimonials/footer scaffolds reduce distinctiveness.
- **Uncommitted style**: mixing multiple archetypes without a rule produces bland output.
- **Token drift**: ad-hoc spacing or color overrides erode system coherence.
- **Decorative motion**: movement without UX purpose increases noise and perceived latency.
- **Over-generic assets**: stock iconography and random illustrations weaken the selected direction.

## Delivery Checklist

Before finalizing output, confirm:

1. Archetype and differentiator are named before code.
2. The differentiator is implemented, not just described.
3. Tokens are explicit and used consistently.
4. Mobile and desktop remain intentional, not auto-collapsed.
5. There is no obvious generic scaffolding left.
