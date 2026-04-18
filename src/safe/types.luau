export type Safe = <Ok, Err>(callbacks: { try: () -> Ok, fallback: (err: unknown) -> Err }) -> Ok | Err

return nil
