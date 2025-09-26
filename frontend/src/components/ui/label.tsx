import { cn } from "@/lib/utils"
import * as LabelPrimitive from "@radix-ui/react-label"
import { cva, type VariantProps } from "class-variance-authority"
import * as React from "react"

const labelVariants = cva(
    "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
)

const Label = React.forwardRef<
    React.ElementRef<typeof LabelPrimitive.Root>,
    React.ComponentPropsWithoutRef<typeof LabelPrimitive.Root> &
    VariantProps<typeof labelVariants>
>(({ className, ...props }, ref) => (
    <LabelPrimitive.Root
        ref={ref}
        className={cn(labelVariants(), className)}
        {...props}
    />
))
Label.displayName = LabelPrimitive.Root.displayName

// Field Label with optional indicator
interface FieldLabelProps extends React.ComponentPropsWithoutRef<typeof LabelPrimitive.Root> {
    required?: boolean
    optional?: boolean
    error?: boolean
    hint?: string
}

const FieldLabel = React.forwardRef<
    React.ElementRef<typeof LabelPrimitive.Root>,
    FieldLabelProps
>(({ className, children, required, optional, error, hint, ...props }, ref) => (
    <div className="space-y-1">
        <LabelPrimitive.Root
            ref={ref}
            className={cn(
                labelVariants(),
                error && "text-destructive",
                className
            )}
            {...props}
        >
            {children}
            {required && <span className="text-destructive ml-1">*</span>}
            {optional && <span className="text-muted-foreground ml-1 text-xs">(optional)</span>}
        </LabelPrimitive.Root>
        {hint && (
            <p className={cn(
                "text-xs",
                error ? "text-destructive" : "text-muted-foreground"
            )}>
                {hint}
            </p>
        )}
    </div>
))
FieldLabel.displayName = "FieldLabel"

// Form Field wrapper
interface FormFieldProps {
    label: string
    error?: string
    hint?: string
    required?: boolean
    optional?: boolean
    children: React.ReactNode
    className?: string
}

const FormField = React.forwardRef<HTMLDivElement, FormFieldProps>(
    ({ label, error, hint, required, optional, children, className, ...props }, ref) => (
        <div
            ref={ref}
            className={cn("space-y-2", className)}
            {...props}
        >
            <FieldLabel
                required={required}
                optional={optional}
                error={!!error}
                hint={hint}
            >
                {label}
            </FieldLabel>
            {children}
            {error && (
                <p className="text-xs text-destructive">{error}</p>
            )}
        </div>
    )
)
FormField.displayName = "FormField"

export { FieldLabel, FormField, Label, labelVariants }
