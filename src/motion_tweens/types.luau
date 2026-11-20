--!strict

export type EasingDirection = "in" | "inout" | "out"

export type DifferentialEasingStyle = (number) -> ...number
export type DifferentialEasingStyles = {
	linear: DifferentialEasingStyle,
	constant: DifferentialEasingStyle,
	quad: DifferentialEasingStyle,
	cubic: DifferentialEasingStyle,
	quart: DifferentialEasingStyle,
	quint: DifferentialEasingStyle,
	sine: DifferentialEasingStyle,
	exponential: DifferentialEasingStyle,
	circular: DifferentialEasingStyle,
}

return nil
