import { cn } from "@/lib/utils"
import * as ProgressPrimitive from "@radix-ui/react-progress"
import * as React from "react"

const Progress = React.forwardRef<
    React.ElementRef<typeof ProgressPrimitive.Root>,
    React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root>
>(({ className, value, ...props }, ref) => (
    <ProgressPrimitive.Root
        ref={ref}
        className={cn(
            "relative h-2 w-full overflow-hidden rounded-full bg-primary/20",
            className
        )}
        {...props}
    >
        <ProgressPrimitive.Indicator
            className="h-full w-full flex-1 bg-primary transition-all"
            style={{ transform: `translateX(-${100 - (value || 0)}%)` }}
        />
    </ProgressPrimitive.Root>
))
Progress.displayName = ProgressPrimitive.Root.displayName

// Circular Progress component
interface CircularProgressProps extends React.HTMLAttributes<HTMLDivElement> {
    value: number
    size?: number
    strokeWidth?: number
    color?: string
    showValue?: boolean
}

const CircularProgress = React.forwardRef<HTMLDivElement, CircularProgressProps>(
    ({ className, value, size = 40, strokeWidth = 4, color = "currentColor", showValue = false, ...props }, ref) => {
        const radius = (size - strokeWidth) / 2
        const circumference = radius * 2 * Math.PI
        const offset = circumference - (value / 100) * circumference

        return (
            <div
                ref={ref}
                className={cn("relative inline-flex items-center justify-center", className)}
                style={{ width: size, height: size }}
                {...props}
            >
                <svg
                    className="transform -rotate-90"
                    width={size}
                    height={size}
                >
                    <circle
                        cx={size / 2}
                        cy={size / 2}
                        r={radius}
                        stroke="currentColor"
                        strokeWidth={strokeWidth}
                        fill="transparent"
                        className="opacity-20"
                    />
                    <circle
                        cx={size / 2}
                        cy={size / 2}
                        r={radius}
                        stroke={color}
                        strokeWidth={strokeWidth}
                        fill="transparent"
                        strokeDasharray={circumference}
                        strokeDashoffset={offset}
                        strokeLinecap="round"
                        className="transition-all duration-300 ease-in-out"
                    />
                </svg>
                {showValue && (
                    <span className="absolute text-xs font-medium">
                        {Math.round(value)}%
                    </span>
                )}
            </div>
        )
    }
)
CircularProgress.displayName = "CircularProgress"

// Step Progress component
interface StepProgressProps extends React.HTMLAttributes<HTMLDivElement> {
    steps: string[]
    currentStep: number
}

const StepProgress = React.forwardRef<HTMLDivElement, StepProgressProps>(
    ({ className, steps, currentStep, ...props }, ref) => {
        return (
            <div
                ref={ref}
                className={cn("w-full", className)}
                {...props}
            >
                <div className="flex items-center justify-between">
                    {steps.map((step, index) => {
                        const isActive = index <= currentStep
                        const isCompleted = index < currentStep

                        return (
                            <React.Fragment key={index}>
                                <div className="flex flex-col items-center">
                                    <div
                                        className={cn(
                                            "flex h-8 w-8 items-center justify-center rounded-full border-2 text-sm font-medium",
                                            isCompleted
                                                ? "border-primary bg-primary text-primary-foreground"
                                                : isActive
                                                    ? "border-primary bg-background text-primary"
                                                    : "border-muted-foreground bg-background text-muted-foreground"
                                        )}
                                    >
                                        {isCompleted ? "✓" : index + 1}
                                    </div>
                                    <span
                                        className={cn(
                                            "mt-2 text-xs",
                                            isActive ? "text-foreground" : "text-muted-foreground"
                                        )}
                                    >
                                        {step}
                                    </span>
                                </div>
                                {index < steps.length - 1 && (
                                    <div
                                        className={cn(
                                            "h-0.5 flex-1 mx-4",
                                            isCompleted ? "bg-primary" : "bg-muted"
                                        )}
                                    />
                                )}
                            </React.Fragment>
                        )
                    })}
                </div>
            </div>
        )
    }
)
StepProgress.displayName = "StepProgress"

// Progress with label
interface LabeledProgressProps extends React.ComponentPropsWithoutRef<typeof ProgressPrimitive.Root> {
    className?: string
    label?: string
    showValue?: boolean
    valueFormatter?: (value: number) => string
    value?: number
}

const LabeledProgress = React.forwardRef<
    React.ElementRef<typeof ProgressPrimitive.Root>,
    LabeledProgressProps
>(({ className, value, label, showValue = true, valueFormatter = (v) => `${v}%`, ...props }, ref) => (
    <div className="w-full space-y-2">
        {(label || showValue) && (
            <div className="flex justify-between text-sm">
                {label && <span className="font-medium">{label}</span>}
                {showValue && <span className="text-muted-foreground">{valueFormatter(value || 0)}</span>}
            </div>
        )}
        <Progress
            ref={ref}
            className={className}
            value={value}
            {...props}
        />
    </div>
))
LabeledProgress.displayName = "LabeledProgress"

// Multiple Progress bars
interface MultiProgressProps extends React.HTMLAttributes<HTMLDivElement> {
    data: Array<{
        value: number
        color?: string
        label?: string
    }>
}

const MultiProgress = React.forwardRef<HTMLDivElement, MultiProgressProps>(
    ({ className, data, ...props }, ref) => {
        const total = data.reduce((sum, item) => sum + item.value, 0)

        return (
            <div
                ref={ref}
                className={cn("w-full space-y-2", className)}
                {...props}
            >
                <div className="flex h-2 w-full overflow-hidden rounded-full bg-primary/20">
                    {data.map((item, index) => {
                        const percentage = total > 0 ? (item.value / total) * 100 : 0
                        return (
                            <div
                                key={index}
                                className={cn(
                                    "transition-all",
                                    item.color || "bg-primary"
                                )}
                                style={{ width: `${percentage}%` }}
                            />
                        )
                    })}
                </div>
                {data.some(item => item.label) && (
                    <div className="flex flex-wrap gap-4 text-xs">
                        {data.map((item, index) => (
                            item.label && (
                                <div key={index} className="flex items-center gap-2">
                                    <div
                                        className={cn(
                                            "h-2 w-2 rounded-full",
                                            item.color || "bg-primary"
                                        )}
                                    />
                                    <span>{item.label}: {item.value}</span>
                                </div>
                            )
                        ))}
                    </div>
                )}
            </div>
        )
    }
)
MultiProgress.displayName = "MultiProgress"

export { CircularProgress, LabeledProgress, MultiProgress, Progress, StepProgress }
