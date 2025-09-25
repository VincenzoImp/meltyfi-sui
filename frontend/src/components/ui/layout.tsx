import { cn } from "@/lib/utils"
import * as React from "react"

// Main layout wrapper
interface LayoutProps extends React.HTMLAttributes<HTMLDivElement> {
    children: React.ReactNode
}

const Layout = React.forwardRef<HTMLDivElement, LayoutProps>(
    ({ className, children, ...props }, ref) => (
        <div
            ref={ref}
            className={cn("min-h-screen bg-background", className)}
            {...props}
        >
            {children}
        </div>
    )
)
Layout.displayName = "Layout"

// Container component
interface ContainerProps extends React.HTMLAttributes<HTMLDivElement> {
    size?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | 'full'
}

const Container = React.forwardRef<HTMLDivElement, ContainerProps>(
    ({ className, size = 'lg', ...props }, ref) => {
        const sizeClasses = {
            sm: 'max-w-2xl',
            md: 'max-w-4xl',
            lg: 'max-w-6xl',
            xl: 'max-w-7xl',
            '2xl': 'max-w-screen-2xl',
            full: 'max-w-full'
        }

        return (
            <div
                ref={ref}
                className={cn(
                    "mx-auto px-4 sm:px-6 lg:px-8",
                    sizeClasses[size],
                    className
                )}
                {...props}
            />
        )
    }
)
Container.displayName = "Container"

// Section component
interface SectionProps extends React.HTMLAttributes<HTMLElement> {
    padding?: 'none' | 'sm' | 'md' | 'lg' | 'xl'
}

const Section = React.forwardRef<HTMLElement, SectionProps>(
    ({ className, padding = 'lg', ...props }, ref) => {
        const paddingClasses = {
            none: '',
            sm: 'py-8 sm:py-12',
            md: 'py-12 sm:py-16',
            lg: 'py-16 sm:py-20',
            xl: 'py-20 sm:py-24'
        }

        return (
            <section
                ref={ref}
                className={cn(paddingClasses[padding], className)}
                {...props}
            />
        )
    }
)
Section.displayName = "Section"

// Grid component
interface GridProps extends React.HTMLAttributes<HTMLDivElement> {
    cols?: 1 | 2 | 3 | 4 | 5 | 6 | 12
    gap?: 'sm' | 'md' | 'lg' | 'xl'
    responsive?: boolean
}

const Grid = React.forwardRef<HTMLDivElement, GridProps>(
    ({ className, cols = 1, gap = 'md', responsive = true, ...props }, ref) => {
        const colClasses = {
            1: 'grid-cols-1',
            2: 'grid-cols-1 md:grid-cols-2',
            3: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
            4: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-4',
            5: 'grid-cols-1 md:grid-cols-3 lg:grid-cols-5',
            6: 'grid-cols-1 md:grid-cols-3 lg:grid-cols-6',
            12: 'grid-cols-12'
        }

        const gapClasses = {
            sm: 'gap-2',
            md: 'gap-4',
            lg: 'gap-6',
            xl: 'gap-8'
        }

        return (
            <div
                ref={ref}
                className={cn(
                    "grid",
                    responsive ? colClasses[cols] : `grid-cols-${cols}`,
                    gapClasses[gap],
                    className
                )}
                {...props}
            />
        )
    }
)
Grid.displayName = "Grid"

// Flex component
interface FlexProps extends React.HTMLAttributes<HTMLDivElement> {
    direction?: 'row' | 'col' | 'row-reverse' | 'col-reverse'
    align?: 'start' | 'center' | 'end' | 'stretch' | 'baseline'
    justify?: 'start' | 'center' | 'end' | 'between' | 'around' | 'evenly'
    gap?: 'sm' | 'md' | 'lg' | 'xl'
    wrap?: boolean
}

const Flex = React.forwardRef<HTMLDivElement, FlexProps>(
    ({
        className,
        direction = 'row',
        align = 'start',
        justify = 'start',
        gap = 'md',
        wrap = false,
        ...props
    }, ref) => {
        const directionClasses = {
            row: 'flex-row',
            col: 'flex-col',
            'row-reverse': 'flex-row-reverse',
            'col-reverse': 'flex-col-reverse'
        }

        const alignClasses = {
            start: 'items-start',
            center: 'items-center',
            end: 'items-end',
            stretch: 'items-stretch',
            baseline: 'items-baseline'
        }

        const justifyClasses = {
            start: 'justify-start',
            center: 'justify-center',
            end: 'justify-end',
            between: 'justify-between',
            around: 'justify-around',
            evenly: 'justify-evenly'
        }

        const gapClasses = {
            sm: 'gap-2',
            md: 'gap-4',
            lg: 'gap-6',
            xl: 'gap-8'
        }

        return (
            <div
                ref={ref}
                className={cn(
                    "flex",
                    directionClasses[direction],
                    alignClasses[align],
                    justifyClasses[justify],
                    gapClasses[gap],
                    wrap && 'flex-wrap',
                    className
                )}
                {...props}
            />
        )
    }
)
Flex.displayName = "Flex"

// Stack component (vertical flex)
interface StackProps extends Omit<FlexProps, 'direction'> {
    space?: 'sm' | 'md' | 'lg' | 'xl'
}

const Stack = React.forwardRef<HTMLDivElement, StackProps>(
    ({ space = 'md', ...props }, ref) => (
        <Flex
            ref={ref}
            direction="col"
            gap={space}
            {...props}
        />
    )
)
Stack.displayName = "Stack"

// Center component
interface CenterProps extends React.HTMLAttributes<HTMLDivElement> {
    inline?: boolean
}

const Center = React.forwardRef<HTMLDivElement, CenterProps>(
    ({ className, inline = false, ...props }, ref) => (
        <div
            ref={ref}
            className={cn(
                inline ? "inline-flex" : "flex",
                "items-center justify-center",
                className
            )}
            {...props}
        />
    )
)
Center.displayName = "Center"

// Spacer component
interface SpacerProps extends React.HTMLAttributes<HTMLDivElement> {
    size?: 'sm' | 'md' | 'lg' | 'xl' | '2xl'
    axis?: 'x' | 'y' | 'both'
}

const Spacer = React.forwardRef<HTMLDivElement, SpacerProps>(
    ({ className, size = 'md', axis = 'y', ...props }, ref) => {
        const sizeClasses = {
            sm: '4',
            md: '8',
            lg: '12',
            xl: '16',
            '2xl': '20'
        }

        const spacingClass = axis === 'x'
            ? `w-${sizeClasses[size]}`
            : axis === 'y'
                ? `h-${sizeClasses[size]}`
                : `w-${sizeClasses[size]} h-${sizeClasses[size]}`

        return (
            <div
                ref={ref}
                className={cn(spacingClass, className)}
                {...props}
            />
        )
    }
)
Spacer.displayName = "Spacer"

// Main content area
interface MainProps extends React.HTMLAttributes<HTMLElement> {
    padded?: boolean
}

const Main = React.forwardRef<HTMLElement, MainProps>(
    ({ className, padded = true, ...props }, ref) => (
        <main
            ref={ref}
            className={cn(
                "flex-1",
                padded && "py-8 sm:py-12",
                className
            )}
            {...props}
        />
    )
)
Main.displayName = "Main"

// Header component
interface HeaderProps extends React.HTMLAttributes<HTMLElement> {
    sticky?: boolean
    blur?: boolean
}

const Header = React.forwardRef<HTMLElement, HeaderProps>(
    ({ className, sticky = false, blur = false, ...props }, ref) => (
        <header
            ref={ref}
            className={cn(
                sticky && "sticky top-0 z-50",
                blur && "backdrop-blur-md bg-background/80",
                "border-b border-border",
                className
            )}
            {...props}
        />
    )
)
Header.displayName = "Header"

// Footer component
const Footer = React.forwardRef<HTMLElement, React.HTMLAttributes<HTMLElement>>(
    ({ className, ...props }, ref) => (
        <footer
            ref={ref}
            className={cn(
                "border-t border-border bg-background",
                className
            )}
            {...props}
        />
    )
)
Footer.displayName = "Footer"

// Sidebar component
interface SidebarProps extends React.HTMLAttributes<HTMLElement> {
    position?: 'left' | 'right'
    width?: 'sm' | 'md' | 'lg'
}

const Sidebar = React.forwardRef<HTMLElement, SidebarProps>(
    ({ className, position = 'left', width = 'md', ...props }, ref) => {
        const widthClasses = {
            sm: 'w-48',
            md: 'w-64',
            lg: 'w-80'
        }

        return (
            <aside
                ref={ref}
                className={cn(
                    widthClasses[width],
                    "shrink-0",
                    className
                )}
                {...props}
            />
        )
    }
)
Sidebar.displayName = "Sidebar"

export {
    Center, Container, Flex, Footer, Grid, Header, Layout, Main, Section, Sidebar, Spacer, Stack
}
