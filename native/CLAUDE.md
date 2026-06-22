# Sky Native

- Done means `xcodegen generate && ./build-mac.sh` passes from this directory.
- `project.yml` is the Xcode source of truth. Never edit `Sky.xcodeproj` by hand.
- Compose UI from `Sky/DesignSystem` primitives and tokens. Use native Liquid Glass only through `GlassCard` or `glassSurface()`; no raw spacing, radius, size, or color values in views.
- Use the `swiftui-specialist` skill for SwiftUI work.
- Use one branch per task.
- If `backend/app/api` changes an API shape, update the matching `Sky/Models/*.swift` type against `backend/lib/types.ts`.
- Design decisions and token values: [`../docs/DESIGN.md`](../docs/DESIGN.md).
