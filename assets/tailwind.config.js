module.exports = {
  darkMode: 'class',
  purge: {
    enabled: true,
    content: ['../lib/**/*.eex', '../lib/**/*.leex', '../lib/stream_closed_captioner_phoenix_web/live/page_live.html.leex'],
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
