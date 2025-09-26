import { cn } from "@/lib/utils"
import { cva, type VariantProps } from "class-variance-authority"
import { Eye, EyeOff, Search } from "lucide-react"
import * as React from "react"

const inputVariants = cva(
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
    {
        variants: {
            size: {
                default: "h-9 px-3 py-1",
                sm: "h-8 px-2 text-xs",
                lg: "h-10 px-4 py-2",
            },
        },
        defaultVariants: {
            size: "default",
        },
    }
)

export interface InputProps
    extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'size'>,
    VariantProps<typeof inputVariants> {
    size?: "default" | "sm" | "lg"
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
    ({ className, type, size, ...props }, ref) => {
        return (
            <input
                type={type}
                className={cn(inputVariants({ size, className }))}
                ref={ref}
                {...props}
            />
        )
    }
)
Input.displayName = "Input"

// Search Input variant
export interface SearchInputProps extends Omit<InputProps, 'type'> {
    onClear?: () => void
}

const SearchInput = React.forwardRef<HTMLInputElement, SearchInputProps>(
    ({ className, onClear, ...props }, ref) => {
        return (
            <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                    ref={ref}
                    type="search"
                    className={cn("pl-10", className)}
                    {...props}
                />
            </div>
        )
    }
)
SearchInput.displayName = "SearchInput"

// Password Input with toggle visibility
export interface PasswordInputProps extends Omit<InputProps, 'type'> { }

const PasswordInput = React.forwardRef<HTMLInputElement, PasswordInputProps>(
    ({ className, ...props }, ref) => {
        const [showPassword, setShowPassword] = React.useState(false)

        return (
            <div className="relative">
                <Input
                    ref={ref}
                    type={showPassword ? "text" : "password"}
                    className={cn("pr-10", className)}
                    {...props}
                />
                <button
                    type="button"
                    className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    onClick={() => setShowPassword(!showPassword)}
                >
                    {showPassword ? <EyeOff /> : <Eye />}
                </button>
            </div>
        )
    }
)
PasswordInput.displayName = "PasswordInput"

// Number Input with increment/decrement buttons
export interface NumberInputProps extends Omit<InputProps, 'type'> {
    min?: number
    max?: number
    step?: number
    onIncrement?: () => void
    onDecrement?: () => void
}

const NumberInput = React.forwardRef<HTMLInputElement, NumberInputProps>(
    ({ className, min, max, step = 1, onIncrement, onDecrement, ...props }, ref) => {
        const [value, setValue] = React.useState<number>(Number(props.defaultValue) || 0)

        const handleIncrement = () => {
            const newValue = Math.min((max || Infinity), value + step)
            setValue(newValue)
            onIncrement?.()
            props.onChange?.({ target: { value: newValue.toString() } } as any)
        }

        const handleDecrement = () => {
            const newValue = Math.max((min || -Infinity), value - step)
            setValue(newValue)
            onDecrement?.()
            props.onChange?.({ target: { value: newValue.toString() } } as any)
        }

        const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
            const newValue = Number(e.target.value)
            setValue(newValue)
            props.onChange?.(e)
        }

        return (
            <div className="relative">
                <Input
                    ref={ref}
                    type="number"
                    min={min}
                    max={max}
                    step={step}
                    value={value}
                    onChange={handleChange}
                    className={cn("pr-20", className)}
                    {...props}
                />
                <div className="absolute right-1 top-1/2 flex -translate-y-1/2 flex-col">
                    <button
                        type="button"
                        className="h-4 w-6 rounded-sm hover:bg-accent text-xs"
                        onClick={handleIncrement}
                        disabled={max !== undefined && value >= max}
                    >
                        +
                    </button>
                    <button
                        type="button"
                        className="h-4 w-6 rounded-sm hover:bg-accent text-xs"
                        onClick={handleDecrement}
                        disabled={min !== undefined && value <= min}
                    >
                        -
                    </button>
                </div>
            </div>
        )
    }
)
NumberInput.displayName = "NumberInput"

// File Input
export interface FileInputProps extends Omit<InputProps, 'type'> {
    accept?: string
}

const FileInput = React.forwardRef<HTMLInputElement, FileInputProps>(
    ({ className, ...props }, ref) => {
        return (
            <Input
                ref={ref}
                type="file"
                className={cn(
                    "file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary file:text-primary-foreground hover:file:bg-primary/80",
                    className
                )}
                {...props}
            />
        )
    }
)
FileInput.displayName = "FileInput"

export { FileInput, Input, inputVariants, NumberInput, PasswordInput, SearchInput }
