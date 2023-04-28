(require '[datomic.api :as d])

(d/create-database (System/getenv "DATOMIC_DATABASE_URL"))
