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

def create_cards(db, template_name, card_amount, owner)
    old_amount = db.execute("SELECT amount FROM template where name=?", [template_name])
    new_card_amount = card_amount.to_i + old_amount[0][0].to_i
    
    db.execute("UPDATE template SET amount = ? WHERE name = ?", [new_card_amount, template_name])
    
    count = db.execute("SELECT COUNT(*) FROM card")
    card_id = count[0][0].to_i + 1
    this_card_id=[]
    
    i = 0
    history = Time.now.to_s
    while i < card_amount.to_i
        db.execute("INSERT INTO card(template, history) VALUES (?,?)", [template_name, history])
        this_card_id << card_id.to_i + i
        
        i=i+1
    end
    current_cards = db.execute("SELECT cards FROM users WHERE name = ?", [owner])[0]
    new_cards = current_cards + this_card_id
    new_cards = new_cards.join(', ')
    
    db.execute("UPDATE users SET cards = ? WHERE name = ?", [new_cards, owner])
    
end

def show_all_cards(db)
    
    return db.execute("SELECT * FROM template")
end

def show_user_cards(db, username)
    owned_cards = db.execute("SELECT cards FROM users WHERE name=?", username)
    if owned_cards[0][0] != nil
        owned_cards = owned_cards[0][0].split(', ')
    end
    
    
    show_these = []
    i = 0
    while i < owned_cards.length
        current = db.execute("SELECT template FROM card WHERE id=?", owned_cards[i+1])
        
        show_these << current
        i = i + 1
    end
    
    amounter=[]
    b = Hash.new(0)
    
    show_these.each do |v|
        b[v] += 1
    end
    
    b.each do |k, v|
        amounter << "#{v} copies of #{k}"
    end
    p amounter

    owned_templates = show_these.uniq
    
    i = 0
    while i < owned_templates.length
        owned_templates[i] << amounter[i]
        i += 1
    end
    return owned_templates
end

def create_trade(db, cards, name, users, expiration)
    
    db.execute("INSERT INTO trades(cards, name, users, expiration) VALUES (?,?,?,?)", [cards, name, users, expiration])

end

def show_all_trades(db)
    return db.execute("SELECT * FROM trades")

end

def show_user_trades(db, username)
    return db.execute("SELECT * FROM trades WHERE users=?", username)

end

def user_owns_cards(db, username)

    does = false
    if db.execute("SELECT cards FROM users WHERE name=?", username) != nil
        does = true
    end

    return does
end