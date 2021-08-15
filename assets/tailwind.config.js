module.exports = {
  darkMode: 'class',
  purge: {
    enabled: process.env.MIX_ENV === 'prod',
    content: ['../lib/**/*.eex', '../lib/**/*.leex', '../lib/stream_closed_captioner_phoenix_web/live/page_live.html.leex'],
    options: {
      whitelist: [],
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('kutty'),
    require('@tailwindcss/typography'),
    require("nightwind")
  ],
  theme: {
    nightwind: {
      colors: {
        white: "gray.800",
      },
    },
  },
};
