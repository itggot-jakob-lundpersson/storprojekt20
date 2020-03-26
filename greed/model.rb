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

def template_name_validation(db, template_name)
    exists = db.execute("SELECT name FROM template WHERE name=?", template_name)

    if exists==[]
        result = true
        
    else
        result = false
        

    end


    return result
end

def create_template(db, template_name, rarity, description, tags, collection, image_link)
    db.execute("INSERT INTO template(name, rarity, description, tag, collection, image) VALUES (?,?,?,?,?,?)", [template_name, rarity, description, tags, collection, image_link])
    

end

def create_cards(db, template_name, card_amount)
    old_amount = db.execute("SELECT amount FROM template where name=?", [template_name])
    new_card_amount = card_amount.to_i + old_amount[0][0].to_i

    db.execute("UPDATE template SET amount = ? WHERE name = ?", [new_card_amount, template_name])
    i = 0
    history = Time.now.to_s
    while i <= card_amount.to_i
        db.execute("INSERT INTO card(template, history) VALUES (?,?)", [template_name, history])
        i=i+1
    end


end