const colors = require('tailwindcss/colors');
const plugin = require('tailwindcss/plugin');

module.exports = {
  darkMode: 'class',
  content: {
    content: ['./js/**/*.js',
      '../lib/*_web.ex',
      '../lib/*_web/**/*.*ex'
    ],
    options: {
      safelist: ['dark'],
    }
  },
  plugins: [
    require('nightwind'),
    require('@tailwindcss/aspect-ratio'),
    require('kutty'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    plugin(({ addVariant }) => addVariant('phx-no-feedback', ['.phx-no-feedback&', '.phx-no-feedback &'])),
    plugin(({ addVariant }) => addVariant('phx-click-loading', ['.phx-click-loading&', '.phx-click-loading &'])),
    plugin(({ addVariant }) => addVariant('phx-submit-loading', ['.phx-submit-loading&', '.phx-submit-loading &'])),
    plugin(({ addVariant }) => addVariant('phx-change-loading', ['.phx-change-loading&', '.phx-change-loading &'])),
  ],
  theme: {
    extend: {
      colors: {
        green: colors.emerald,
        yellow: colors.amber,
        purple: colors.violet,
      }
    },
    nightwind: {
      colors: {
        white: 'gray.800',
        red: {
          100: 'red.100',
        },
        yellow: {
          100: 'yellow.100',
        },
      },
    },
  },
};
