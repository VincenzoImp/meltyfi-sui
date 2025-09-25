'use client'

import { Button, IconButton } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { cn } from "@/lib/utils"
import {
    Github,
    Home,
    Menu,
    Moon,
    Sun,
    Trophy,
    User,
    Wallet,
    X
} from "lucide-react"
import { useTheme } from "next-themes"
import Link from "next/link"
import { usePathname } from "next/navigation"
import * as React from "react"

interface NavItem {
    href: string
    label: string
    icon: React.ReactNode
    external?: boolean
}

const navigationItems: NavItem[] = [
    {
        href: "/",
        label: "Home",
        icon: <Home className="h-4 w-4" />
    },
    {
        href: "/lotteries",
        label: "Lotteries",
        icon: <Trophy className="h-4 w-4" />
    },
    {
        href: "/profile",
        label: "Profile",
        icon: <User className="h-4 w-4" />
    },
    {
        href: "https://github.com/VincenzoImp/MeltyFi",
        label: "GitHub",
        icon: <Github className="h-4 w-4" />,
        external: true
    }
]

interface NavigationProps {
    className?: string
}

export function Navigation({ className }: NavigationProps) {
    const [isOpen, setIsOpen] = React.useState(false)
    const [isScrolled, setIsScrolled] = React.useState(false)
    const { theme, setTheme } = useTheme()
    const pathname = usePathname()

    // Handle scroll effect
    React.useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 20)
        }
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    // Close mobile menu on route change
    React.useEffect(() => {
        setIsOpen(false)
    }, [pathname])

    const toggleTheme = () => {
        setTheme(theme === 'dark' ? 'light' : 'dark')
    }

    return (
        <>
            {/* Main Navigation */}
            <nav className={cn(
                "sticky top-0 z-50 w-full transition-all duration-200",
                isScrolled
                    ? "bg-background/80 backdrop-blur-md border-b shadow-sm"
                    : "bg-transparent",
                className
            )}>
                <div className="container mx-auto px-4">
                    <div className="flex items-center justify-between h-16">
                        {/* Logo */}
                        <Link
                            href="/"
                            className="flex items-center space-x-2 group"
                        >
                            <div className="relative">
                                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-melty-gold-400 to-melty-chocolate-500 shadow-lg group-hover:shadow-xl transition-shadow duration-200" />
                                <div className="absolute inset-0 rounded-lg bg-gradient-to-br from-melty-gold-400 to-melty-chocolate-500 opacity-0 group-hover:opacity-20 blur-md transition-opacity duration-200" />
                            </div>
                            <span className="font-bold text-xl bg-gradient-to-r from-primary to-melty-gold-500 bg-clip-text text-transparent">
                                MeltyFi
                            </span>
                        </Link>

                        {/* Desktop Navigation */}
                        <div className="hidden md:flex items-center space-x-1">
                            {navigationItems.map((item) => {
                                const isActive = pathname === item.href
                                const isExternal = item.external

                                if (isExternal) {
                                    return (
                                        <a
                                            key={item.href}
                                            href={item.href}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className={cn(
                                                "flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200",
                                                "hover:bg-primary/10 hover:text-primary",
                                                "text-muted-foreground"
                                            )}
                                        >
                                            {item.icon}
                                            <span>{item.label}</span>
                                        </a>
                                    )
                                }

                                return (
                                    <Link
                                        key={item.href}
                                        href={item.href}
                                        className={cn(
                                            "flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200",
                                            isActive
                                                ? "bg-primary text-primary-foreground shadow-sm"
                                                : "text-muted-foreground hover:bg-primary/10 hover:text-primary"
                                        )}
                                    >
                                        {item.icon}
                                        <span>{item.label}</span>
                                    </Link>
                                )
                            })}
                        </div>

                        {/* Actions */}
                        <div className="flex items-center space-x-2">
                            {/* Theme Toggle */}
                            <IconButton
                                variant="ghost"
                                size="icon-sm"
                                onClick={toggleTheme}
                                icon={theme === 'dark' ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
                            >
                                Toggle theme
                            </IconButton>

                            {/* Wallet Connection - Placeholder */}
                            <Button variant="outline" size="sm" className="hidden sm:flex">
                                <Wallet className="h-4 w-4" />
                                Connect Wallet
                            </Button>

                            {/* Mobile Menu Toggle */}
                            <IconButton
                                variant="ghost"
                                size="icon-sm"
                                className="md:hidden"
                                onClick={() => setIsOpen(!isOpen)}
                                icon={isOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
                            >
                                {isOpen ? 'Close menu' : 'Open menu'}
                            </IconButton>
                        </div>
                    </div>
                </div>
            </nav>

            {/* Mobile Menu Overlay */}
            {isOpen && (
                <div className="fixed inset-0 z-40 md:hidden">
                    <div
                        className="fixed inset-0 bg-background/80 backdrop-blur-sm"
                        onClick={() => setIsOpen(false)}
                    />
                </div>
            )}

            {/* Mobile Menu */}
            <div className={cn(
                "fixed top-16 left-0 right-0 z-50 md:hidden transition-all duration-200 ease-in-out",
                isOpen
                    ? "translate-y-0 opacity-100"
                    : "-translate-y-full opacity-0 pointer-events-none"
            )}>
                <Card className="m-4 p-4 shadow-xl border-border/50">
                    <div className="space-y-2">
                        {navigationItems.map((item) => {
                            const isActive = pathname === item.href
                            const isExternal = item.external

                            if (isExternal) {
                                return (
                                    <a
                                        key={item.href}
                                        href={item.href}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className={cn(
                                            "flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200",
                                            "hover:bg-primary/10 hover:text-primary text-muted-foreground",
                                            "border border-transparent hover:border-primary/20"
                                        )}
                                    >
                                        {item.icon}
                                        <span>{item.label}</span>
                                    </a>
                                )
                            }

                            return (
                                <Link
                                    key={item.href}
                                    href={item.href}
                                    className={cn(
                                        "flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200",
                                        isActive
                                            ? "bg-primary text-primary-foreground shadow-sm border border-primary/20"
                                            : "text-muted-foreground hover:bg-primary/10 hover:text-primary border border-transparent hover:border-primary/20"
                                    )}
                                >
                                    {item.icon}
                                    <span>{item.label}</span>
                                </Link>
                            )
                        })}

                        {/* Mobile Wallet Button */}
                        <div className="pt-4 border-t border-border/50">
                            <Button
                                variant="outline"
                                size="sm"
                                className="w-full justify-start"
                            >
                                <Wallet className="h-4 w-4" />
                                Connect Wallet
                            </Button>
                        </div>
                    </div>
                </Card>
            </div>
        </>
    )
}

// Breadcrumb component for page navigation
interface BreadcrumbItem {
    label: string
    href?: string
}

interface BreadcrumbProps {
    items: BreadcrumbItem[]
    className?: string
}

export function Breadcrumb({ items, className }: BreadcrumbProps) {
    return (
        <nav className={cn("flex items-center space-x-2 text-sm", className)}>
            {items.map((item, index) => (
                <React.Fragment key={index}>
                    {index > 0 && (
                        <span className="text-muted-foreground">/</span>
                    )}
                    {item.href ? (
                        <Link
                            href={item.href}
                            className="text-muted-foreground hover:text-foreground transition-colors"
                        >
                            {item.label}
                        </Link>
                    ) : (
                        <span className="font-medium text-foreground">
                            {item.label}
                        </span>
                    )}
                </React.Fragment>
            ))}
        </nav>
    )
}

// Page header component
interface PageHeaderProps {
    title: string
    description?: string
    breadcrumb?: BreadcrumbItem[]
    actions?: React.ReactNode
    className?: string
}

export function PageHeader({
    title,
    description,
    breadcrumb,
    actions,
    className
}: PageHeaderProps) {
    return (
        <div className={cn("space-y-4", className)}>
            {breadcrumb && <Breadcrumb items={breadcrumb} />}

            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div className="space-y-2">
                    <h1 className="melty-heading-1">
                        {title}
                    </h1>
                    {description && (
                        <p className="melty-body-large text-muted-foreground max-w-2xl">
                            {description}
                        </p>
                    )}
                </div>

                {actions && (
                    <div className="flex items-center space-x-2">
                        {actions}
                    </div>
                )}
            </div>
        </div>
    )
}