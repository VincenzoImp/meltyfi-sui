import { cn } from "@/lib/utils"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

const textareaVariants = cva(
    "flex min-h-[60px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
    {
        variants: {
            size: {
                default: "min-h-[60px] px-3 py-2",
                sm: "min-h-[50px] px-2 py-1 text-xs",
                lg: "min-h-[80px] px-4 py-3",
            },
        },
        defaultVariants: {
            size: "default",
        },
    }
)

export interface TextareaProps
    extends React.TextareaHTMLAttributes<HTMLTextAreaElement>,
    VariantProps<typeof textareaVariants> {
    resize?: boolean
}

const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
    ({ className, size, resize = true, ...props }, ref) => {
        return (
            <textarea
                className={cn(
                    textareaVariants({ size }),
                    !resize && "resize-none",
                    className
                )}
                ref={ref}
                {...props}
            />
        )
    }
)
Textarea.displayName = "Textarea"

// Auto-resize textarea
interface AutoResizeTextareaProps extends TextareaProps {
    minRows?: number
    maxRows?: number
}

const AutoResizeTextarea = React.forwardRef<HTMLTextAreaElement, AutoResizeTextareaProps>(
    ({ className, minRows = 2, maxRows = 10, ...props }, ref) => {
        const textareaRef = React.useRef<HTMLTextAreaElement>(null)

        React.useImperativeHandle(ref, () => textareaRef.current!, [])

        const adjustHeight = React.useCallback(() => {
            const textarea = textareaRef.current
            if (!textarea) return

            // Reset height to calculate scrollHeight
            textarea.style.height = 'auto'

            // Calculate new height
            const lineHeight = parseInt(window.getComputedStyle(textarea).lineHeight)
            const minHeight = lineHeight * minRows
            const maxHeight = lineHeight * maxRows
            const newHeight = Math.min(Math.max(textarea.scrollHeight, minHeight), maxHeight)

            textarea.style.height = `${newHeight}px`
        }, [minRows, maxRows])

        React.useEffect(() => {
            adjustHeight()
        }, [adjustHeight, props.value])

        return (
            <Textarea
                {...props}
                ref={textareaRef}
                className={cn("resize-none overflow-hidden", className)}
                onInput={adjustHeight}
            />
        )
    }
)
AutoResizeTextarea.displayName = "AutoResizeTextarea"

// Character counter textarea
interface CounterTextareaProps extends TextareaProps {
    maxLength?: number
    showCounter?: boolean
}

const CounterTextarea = React.forwardRef<HTMLTextAreaElement, CounterTextareaProps>(
    ({ className, maxLength, showCounter = true, value, ...props }, ref) => {
        const currentLength = (value as string)?.length || 0
        const isOverLimit = maxLength ? currentLength > maxLength : false

        return (
            <div className="space-y-2">
                <Textarea
                    {...props}
                    ref={ref}
                    value={value}
                    maxLength={maxLength}
                    className={cn(
                        isOverLimit && "border-destructive focus-visible:ring-destructive",
                        className
                    )}
                />
                {showCounter && (
                    <div className="flex justify-end">
                        <span className={cn(
                            "text-xs",
                            isOverLimit ? "text-destructive" : "text-muted-foreground"
                        )}>
                            {currentLength}
                            {maxLength && `/${maxLength}`}
                        </span>
                    </div>
                )}
            </div>
        )
    }
)
CounterTextarea.displayName = "CounterTextarea"

// Textarea with toolbar
interface ToolbarTextareaProps extends TextareaProps {
    onFormat?: (type: 'bold' | 'italic' | 'underline') => void
}

const ToolbarTextarea = React.forwardRef<HTMLTextAreaElement, ToolbarTextareaProps>(
    ({ className, onFormat, ...props }, ref) => {
        return (
            <div className="space-y-2">
                <div className="flex space-x-1 border-b border-border pb-2">
                    <button
                        type="button"
                        className="px-2 py-1 text-xs rounded hover:bg-accent"
                        onClick={() => onFormat?.('bold')}
                    >
                        <strong>B</strong>
                    </button>
                    <button
                        type="button"
                        className="px-2 py-1 text-xs rounded hover:bg-accent"
                        onClick={() => onFormat?.('italic')}
                    >
                        <em>I</em>
                    </button>
                    <button
                        type="button"
                        className="px-2 py-1 text-xs rounded hover:bg-accent"
                        onClick={() => onFormat?.('underline')}
                    >
                        <u>U</u>
                    </button>
                </div>
                <Textarea
                    {...props}
                    ref={ref}
                    className={className}
                />
            </div>
        )
    }
)
ToolbarTextarea.displayName = "ToolbarTextarea"

export {
    AutoResizeTextarea,
    CounterTextarea, Textarea, textareaVariants, ToolbarTextarea
}
