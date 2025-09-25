'use client';
import { ArrowRight, ChevronRight, Coins, DollarSign, Shield, Sparkles, Star, Timer, Trophy, Users, Wallet } from 'lucide-react';
import { useEffect, useState } from 'react';

const MeltyFiHomepage = () => {
  const [currentTestimonial, setCurrentTestimonial] = useState(0);
  const [stats, setStats] = useState({
    totalVolume: 0,
    activeLotteries: 0,
    happyUsers: 0
  });

  // Animate numbers on mount
  useEffect(() => {
    const timer = setTimeout(() => {
      setStats({
        totalVolume: 2500000,
        activeLotteries: 47,
        happyUsers: 1250
      });
    }, 500);
    return () => clearTimeout(timer);
  }, []);

  // Auto-rotate testimonials
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTestimonial((prev) => (prev + 1) % testimonials.length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const testimonials = [
    {
      text: "MeltyFi turned my illiquid NFTs into instant liquidity. The chocolate factory theme makes DeFi actually fun!",
      author: "Alex Chen",
      role: "NFT Collector",
      avatar: "AC"
    },
    {
      text: "Got my loan instantly and repaid early to get my NFT back. The WonkaBar system is genius!",
      author: "Sarah Mitchell",
      role: "Digital Artist",
      avatar: "SM"
    },
    {
      text: "Won a rare NFT through the lottery system. Best DeFi experience I've ever had!",
      author: "Marcus Rodriguez",
      role: "DeFi Enthusiast",
      avatar: "MR"
    }
  ];

  const features = [
    {
      icon: <Coins className="w-8 h-8 text-amber-500" />,
      title: "Instant Liquidity",
      description: "Turn your NFTs into immediate cash flow. Get 95% of funds upfront while keeping ownership rights."
    },
    {
      icon: <Shield className="w-8 h-8 text-blue-500" />,
      title: "Win-Win Mechanics",
      description: "Everyone benefits! Borrowers get liquidity, lenders earn rewards, and someone wins the NFT if defaulted."
    },
    {
      icon: <Trophy className="w-8 h-8 text-purple-500" />,
      title: "Gamified Experience",
      description: "Collect WonkaBars, earn ChocoChips, and participate in exciting lottery-based lending."
    },
    {
      icon: <Timer className="w-8 h-8 text-green-500" />,
      title: "Flexible Terms",
      description: "Set your own loan duration and ticket prices. Repay early to get your NFT back plus rewards."
    }
  ];

  const AnimatedNumber = ({ value, suffix = "" }: { value: number; suffix?: string }) => {
    const [displayValue, setDisplayValue] = useState(0);

    useEffect(() => {
      const duration = 2000;
      const steps = 60;
      const increment = value / steps;
      let current = 0;

      const timer = setInterval(() => {
        current += increment;
        if (current >= value) {
          setDisplayValue(value);
          clearInterval(timer);
        } else {
          setDisplayValue(Math.floor(current));
        }
      }, duration / steps);

      return () => clearInterval(timer);
    }, [value]);

    return (
      <span className="text-4xl font-bold text-white">
        {displayValue.toLocaleString()}{suffix}
      </span>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 text-white overflow-hidden">
      {/* Animated Background Elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-pulse"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-blue-500 rounded-full mix-blend-multiply filter blur-xl opacity-20 animate-pulse" style={{ animationDelay: '2s' }}></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-indigo-500 rounded-full mix-blend-multiply filter blur-xl opacity-10 animate-pulse" style={{ animationDelay: '4s' }}></div>
      </div>

      {/* Navigation */}
      <nav className="relative z-20 px-6 py-4 backdrop-blur-sm bg-white/5 border-b border-white/10">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center shadow-lg">
              <Sparkles className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              MeltyFi
            </span>
          </div>

          <div className="hidden md:flex items-center space-x-8">
            <a href="#" className="hover:text-amber-400 transition-colors">Lotteries</a>
            <a href="#" className="hover:text-amber-400 transition-colors">Profile</a>
            <a href="#" className="hover:text-amber-400 transition-colors">How It Works</a>
            <button className="bg-gradient-to-r from-amber-500 to-orange-500 px-6 py-2 rounded-full hover:shadow-lg hover:shadow-amber-500/25 transition-all duration-300 flex items-center space-x-2">
              <Wallet className="w-4 h-4" />
              <span>Connect Wallet</span>
            </button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative z-10 px-6 pt-20 pb-32">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-6 py-3 mb-8 border border-white/20">
              <Sparkles className="w-5 h-5 text-amber-400" />
              <span className="text-sm font-medium">Welcome to the Chocolate Factory of DeFi</span>
            </div>

            <h1 className="text-7xl md:text-8xl font-bold mb-8 leading-tight">
              <span className="bg-gradient-to-r from-amber-400 via-orange-500 to-red-500 bg-clip-text text-transparent">
                Making the
              </span>
              <br />
              <span className="bg-gradient-to-r from-purple-400 via-pink-500 to-indigo-500 bg-clip-text text-transparent">
                Illiquid Liquid
              </span>
            </h1>

            <p className="text-xl md:text-2xl text-white/80 mb-12 max-w-4xl mx-auto leading-relaxed">
              Transform your NFTs into instant liquidity through our magical lottery-based lending protocol.
              Where Charlie's chocolate factory meets DeFi innovation on the Sui blockchain.
            </p>

            <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-6">
              <button className="bg-gradient-to-r from-amber-500 to-orange-500 px-8 py-4 rounded-full text-lg font-semibold hover:shadow-2xl hover:shadow-amber-500/25 transition-all duration-300 flex items-center space-x-2 group">
                <span>Start Borrowing</span>
                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </button>

              <button className="border border-white/30 px-8 py-4 rounded-full text-lg font-semibold hover:bg-white/10 transition-all duration-300 backdrop-blur-sm">
                Explore Lotteries
              </button>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
            <div className="text-center p-8 rounded-2xl bg-white/5 backdrop-blur-sm border border-white/10 hover:bg-white/10 transition-all duration-300">
              <DollarSign className="w-12 h-12 text-green-400 mx-auto mb-4" />
              <AnimatedNumber value={stats.totalVolume} suffix="+" />
              <p className="text-white/80 mt-2">Total Volume (SUI)</p>
            </div>

            <div className="text-center p-8 rounded-2xl bg-white/5 backdrop-blur-sm border border-white/10 hover:bg-white/10 transition-all duration-300">
              <Trophy className="w-12 h-12 text-amber-400 mx-auto mb-4" />
              <AnimatedNumber value={stats.activeLotteries} />
              <p className="text-white/80 mt-2">Active Lotteries</p>
            </div>

            <div className="text-center p-8 rounded-2xl bg-white/5 backdrop-blur-sm border border-white/10 hover:bg-white/10 transition-all duration-300">
              <Users className="w-12 h-12 text-blue-400 mx-auto mb-4" />
              <AnimatedNumber value={stats.happyUsers} suffix="+" />
              <p className="text-white/80 mt-2">Happy Users</p>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="relative z-10 px-6 py-20 bg-white/5 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-5xl font-bold mb-6 bg-gradient-to-r from-purple-400 to-pink-500 bg-clip-text text-transparent">
              Why Choose MeltyFi?
            </h2>
            <p className="text-xl text-white/80 max-w-3xl mx-auto">
              Experience the sweet taste of liquidity with our innovative features designed to make everyone a winner
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <div key={index} className="p-8 rounded-2xl bg-white/5 backdrop-blur-sm border border-white/10 hover:bg-white/10 hover:border-white/20 transition-all duration-300 group">
                <div className="mb-6 group-hover:scale-110 transition-transform duration-300">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-semibold mb-4">{feature.title}</h3>
                <p className="text-white/80 leading-relaxed">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="relative z-10 px-6 py-20">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-5xl font-bold mb-6 bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
              Sweet & Simple Process
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            <div className="text-center group">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-amber-500 to-orange-500 flex items-center justify-center mx-auto mb-6 shadow-lg group-hover:shadow-2xl group-hover:shadow-amber-500/25 transition-all duration-300">
                <span className="text-2xl font-bold text-white">1</span>
              </div>
              <h3 className="text-2xl font-semibold mb-4">Create Lottery</h3>
              <p className="text-white/80 leading-relaxed">
                Deposit your valuable NFT and set lottery parameters. Get 95% of funds immediately while keeping ownership rights.
              </p>
            </div>

            <div className="text-center group">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center mx-auto mb-6 shadow-lg group-hover:shadow-2xl group-hover:shadow-purple-500/25 transition-all duration-300">
                <span className="text-2xl font-bold text-white">2</span>
              </div>
              <h3 className="text-2xl font-semibold mb-4">Buy WonkaBars</h3>
              <p className="text-white/80 leading-relaxed">
                Lenders purchase WonkaBars (lottery tickets), funding your loan while getting a chance to win your NFT.
              </p>
            </div>

            <div className="text-center group">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center mx-auto mb-6 shadow-lg group-hover:shadow-2xl group-hover:shadow-blue-500/25 transition-all duration-300">
                <span className="text-2xl font-bold text-white">3</span>
              </div>
              <h3 className="text-2xl font-semibold mb-4">Everyone Wins</h3>
              <p className="text-white/80 leading-relaxed">
                Repay to get your NFT back + rewards, or let someone win it fairly through Chainlink VRF lottery system.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="relative z-10 px-6 py-20 bg-white/5 backdrop-blur-sm">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl font-bold mb-16 bg-gradient-to-r from-green-400 to-blue-500 bg-clip-text text-transparent">
            What Our Users Say
          </h2>

          <div className="relative">
            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20">
              <div className="flex justify-center mb-6">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-6 h-6 text-amber-400 fill-current" />
                ))}
              </div>

              <blockquote className="text-xl text-white/90 mb-6 leading-relaxed">
                "{testimonials[currentTestimonial].text}"
              </blockquote>

              <div className="flex items-center justify-center space-x-4">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center font-semibold">
                  {testimonials[currentTestimonial].avatar}
                </div>
                <div className="text-left">
                  <p className="font-semibold text-white">{testimonials[currentTestimonial].author}</p>
                  <p className="text-sm text-white/70">{testimonials[currentTestimonial].role}</p>
                </div>
              </div>
            </div>

            <div className="flex justify-center mt-6 space-x-2">
              {testimonials.map((_, index) => (
                <button
                  key={index}
                  onClick={() => setCurrentTestimonial(index)}
                  className={`w-3 h-3 rounded-full transition-all duration-300 ${index === currentTestimonial ? 'bg-amber-400' : 'bg-white/30'
                    }`}
                />
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative z-10 px-6 py-20">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-5xl font-bold mb-6 bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 bg-clip-text text-transparent">
            Ready to Enter the Factory?
          </h2>
          <p className="text-xl text-white/80 mb-12 leading-relaxed">
            Join thousands of users who've discovered the magic of liquid NFTs.
            Your golden ticket to DeFi innovation awaits!
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-6">
            <button className="bg-gradient-to-r from-purple-600 to-pink-600 px-8 py-4 rounded-full text-lg font-semibold hover:shadow-2xl hover:shadow-purple-500/25 transition-all duration-300 flex items-center space-x-2 group">
              <Sparkles className="w-5 h-5 group-hover:rotate-12 transition-transform" />
              <span>Launch App</span>
              <ChevronRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </button>

            <button className="border border-white/30 px-8 py-4 rounded-full text-lg font-semibold hover:bg-white/10 transition-all duration-300 backdrop-blur-sm">
              Learn More
            </button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-10 px-6 py-12 bg-black/20 backdrop-blur-sm border-t border-white/10">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row items-center justify-between">
            <div className="flex items-center space-x-3 mb-4 md:mb-0">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center">
                <Sparkles className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold bg-gradient-to-r from-amber-400 to-orange-500 bg-clip-text text-transparent">
                MeltyFi
              </span>
            </div>

            <div className="flex items-center space-x-8 text-white/60">
              <a href="#" className="hover:text-white transition-colors">Privacy</a>
              <a href="#" className="hover:text-white transition-colors">Terms</a>
              <a href="#" className="hover:text-white transition-colors">Discord</a>
              <a href="#" className="hover:text-white transition-colors">Twitter</a>
            </div>
          </div>

          <div className="mt-8 pt-8 border-t border-white/10 text-center text-white/60">
            <p>&copy; 2025 MeltyFi Protocol. Making the illiquid liquid, one NFT at a time.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default MeltyFiHomepage;