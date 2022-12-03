module.exports = {
  darkMode: 'class',
  purge: {
    enabled: process.env.MIX_ENV === 'prod',
    content: ['../lib/**/*.eex', '../lib/**/*.heex', '../lib/stream_closed_captioner_phoenix_web/live/page_live.html.heex'],
    options: {
      safelist: ['dark'],
    },
  },
  plugins: [
    require("nightwind"),
    require('@tailwindcss/aspect-ratio'),
    require('kutty'),
    require('@tailwindcss/typography'),
  ],
  theme: {
    nightwind: {
      colors: {
        white: "gray.800",
        red: {
          100: "red.100",
        },
        yellow: {
          100: "yellow.100",
        }
      },
    },
  },
};
