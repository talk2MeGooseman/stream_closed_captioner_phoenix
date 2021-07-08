import { gql } from 'graphql-request'

export const GET_ME = gql`
  {
    me {
      extensionInstalled
    }
  }
`
