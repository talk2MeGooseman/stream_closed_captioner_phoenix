defmodule StreamClosedCaptionerPhoenixWeb.Schema do
 use Absinthe.Schema

 alias StreamClosedCaptionerPhoenixWeb.Schema
 import_types Schema.AccountsTypes


 # Add import type here. Example
 # import_types(Schema.ProductTypes)

 query do
   # Add queries here. Example
   import_fields(:accounts_queries)
 end

 mutation do
   # Add mutations here. Example
   # import_fields(:create_product)
 end
end
