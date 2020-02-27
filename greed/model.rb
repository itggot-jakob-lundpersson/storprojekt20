require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

def connect_db(database)
    choice = SQLite3::Database.new("db/#{database}.db")
    return choice
end

def register_user(db, username, password)
    result = db.execute("SELECT id FROM users WHERE name=?", username)
    if result.empty?
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users(name, password, role) VALUES (?,?,?)", [username, password_digest, "user"])

    end

    return result
end

def retrieve_user_id(db, username)
    
    user_id = db.execute("SELECT ID FROM users WHERE name=?", username)

    return user_id
end

def retrieve_user_password(db, username)
    password_hash = db.execute("SELECT password FROM users WHERE name=?", username)

    return password_hash.first
end

def retrieve_role(db, user_id)
    result = db.execute("SELECT role FROM users WHERE id=?", user_id)
    p result
    return result
end


def password_verification(password_hash, password)
    
    if BCrypt::Password.new(password_hash.first) == password
        verification = true
        
    else
        verification = false
    end

    return verification
end