def connect_db(database)
    choice = SQLite3::Database.new("db/#{databases}.db")
    return choice
end

db = connect_db("greed")

