import ballerina/http;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:4200"],
        maxAge: 84900
    }
}

service / on new http:Listener(9090) {

    # Get list of all users
    # + return - list of  type User
    resource function get users() returns User[] {
        return usersTable.toArray();
    }

    # Gets user by its id
    # + id - id of user
    # + return - if successful returns user record in response body
    resource function get users/[string id]() returns User|InvalidUserId {
        User? user = usersTable[id];
        if user is () {
            return {
                body: {
                    msg: string `Niepoprawne id użytkownika.`
                }
            };
        }
        return user;
    }

    # Add new user
    # + return - if successful returns posted user record in response body
    resource function post users(@http:Payload User newUser) returns CreatedUser|ConflictError {
        // Check if user with given email already exitsts
        boolean isIdTaken = usersTable.hasKey(newUser.id);
        if isIdTaken {
            return {
                body: {
                    msg: string `Wygenerowane id już istnieje w bazie. Ponów przesłanie formularza.`
                }
            };
        }

        // Check if users with given email already exists
        foreach User user in usersTable {
            if user.email == newUser.email {
                return {
                    body: {
                        msg: string `Wprowadzony email jest już wykorzystywany przez innego użytkownika.`
                    }
                };
            }
        }

        usersTable.add(newUser);
        return <CreatedUser>{body: newUser};
    }

    # Select user by id and reset password in user record TODO
    # + return - message about password reset success/failure
    resource function post users/resetPassword(@http:Payload string userEmail) returns ResetSuccessful|InvalidUserEmail {
        foreach User user in usersTable {
            if user.email == userEmail {
                return <ResetSuccessful>{
                    body: {
                        msg: string `Email znajduje się w bazie danych.`
                    }
                };
            }
        }

        return <InvalidUserEmail>{
            body: {
                msg: string `Użytkownik z podanym adresem email nie istnieje.`
            }
        };
    }

    # Login user if credentials are valid
    # + return - message about login succes or details about login failure
    resource function post auth/login(@http:Payload LoginCredentials loginCredentials) returns LoginSuccessful|LoginFailed {
        foreach User user in usersTable {
            if (user.email == loginCredentials.email) && (user.password == loginCredentials.password) {
                return <LoginSuccessful>{
                    body: {
                        msg: string `Logowanie przebiegło pomyślnie.`
                    }
                };
            }
        }

        return <LoginFailed>{
            body: {
                msg: string `Podane dane użytkownika są nieprawidłowe.`
            }
        };
    }
}


public type User record {|
    readonly string id;
    *LoginCredentials;
|};

public type LoginCredentials record {|
    string email;
    string password;
|};

public final table<User> key(id) usersTable = table [
    {id: "user_1", email: "one@email.com", password: "one"},
    {id: "user_2", email: "two@email.com", password: "two"},
    {id: "user_3", email: "three@email.com", password: "three"}
];

// ---- Response types declaration ----
public type CreatedUser record {|
    *http:Created;
    User body;
|};

public type ConflictError record {|
    *http:Conflict;
    Msg body;
|};

public type InvalidUserId record {|
    *http:NotFound;
    Msg body;
|};

public type ResetSuccessful record {|
    *http:Accepted;
    Msg body;
|};

public type InvalidUserEmail record {|
    *http:BadRequest;
    Msg body;
|};

public type LoginSuccessful record {|
    *http:Ok;
    Msg body;
|};

public type LoginFailed record {|
    *http:Unauthorized;
    Msg body;
|};
// ---- Response types declaration ----

public type Msg record {|
    string msg;
|};