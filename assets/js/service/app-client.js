import { GraphQLClient } from "graphql-request";

export const appClient = new GraphQLClient('/api', { headers: {} })
