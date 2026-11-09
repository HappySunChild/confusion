--!strict

export type Space = {
	to_displacement: (position: { number }, relative_to: { number }) -> { number },
	to_position: (displacement: { number }, relative_to: { number }) -> { number },
}
export type Compositor<T> = {
	compose: ({ number }) -> T,
	decompose: (T) -> { number },
	space: Space,
}

return nil
