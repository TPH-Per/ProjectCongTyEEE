import type { Config } from "tailwindcss";

const config: Config = {
    darkMode: ["class"],
    content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx,mdx,vue}",
  ],
  theme: {
  	extend: {
  		colors: {
  			border: "hsl(var(--border))",
  			input: "hsl(var(--input))",
  			ring: "hsl(var(--ring))",
  			background: "hsl(var(--background))",
  			foreground: "hsl(var(--foreground))",
  			primary: {
  				DEFAULT: "hsl(var(--primary))",
  				foreground: "hsl(var(--primary-foreground))",
  			},
  			secondary: {
  				DEFAULT: "hsl(var(--secondary))",
  				foreground: "hsl(var(--secondary-foreground))",
  			},
  			destructive: {
  				DEFAULT: "hsl(var(--destructive))",
  				foreground: "hsl(var(--destructive-foreground))",
  			},
  			muted: {
  				DEFAULT: "hsl(var(--muted))",
  				foreground: "hsl(var(--muted-foreground))",
  			},
  			accent: {
  				DEFAULT: "hsl(var(--accent))",
  				foreground: "hsl(var(--accent-foreground))",
  			},
  			popover: {
  				DEFAULT: "hsl(var(--popover))",
  				foreground: "hsl(var(--popover-foreground))",
  			},
  			card: {
  				DEFAULT: "hsl(var(--card))",
  				foreground: "hsl(var(--card-foreground))",
  			},
  			// Kawaii palette
  			salmon: {
  				50:  "#FFF5F7",
  				100: "#FFE3E6",
  				200: "#FFCBD3",
  				300: "#FFA6B2",
  				400: "#FF8E9C",
  				500: "#FF7B89",
  				600: "#FF5A6E",
  				700: "#E6455A",
  				800: "#B8334A",
  				900: "#8B2538",
  			},
  			cream: "#FFF5F7",
  			navy: "#2C3E50",
  		},
  		borderRadius: {
  			lg: "var(--radius)",
  			md: "calc(var(--radius) - 2px)",
  			sm: "calc(var(--radius) - 4px)",
  		},
  		fontFamily: {
  			sans: ["Nunito", "-apple-system", "BlinkMacSystemFont", "Hiragino Sans", "Yu Gothic", "sans-serif"],
  		},
  	}
  },
  plugins: [require("tailwindcss-animate")],
};
export default config;
