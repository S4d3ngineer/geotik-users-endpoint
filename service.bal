import ballerina/http;

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
                    errmsg: string `Invalid user id`
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
                    errmsg: string `User id ${newUser.id} already exists `
                }
            };
        }

        // Check if users with given email already exists
        foreach User user in usersTable {
            if user.email == newUser.email {
                return {
                    body: {
                        errmsg: string `Provided email address is already taken!`
                    }
                };
            }
        }

        usersTable.add(newUser);
        return <CreatedUser>{body: newUser};
    }
}

public type User record {|
    readonly string id;
    string email;
    string password;
|};


public final table<User> key(id) usersTable = table [
    {id: "user_1", email: "one@email.com", password: "one"},
    {id: "user_2", email: "two@email.com", password: "two"},
    {id: "user_3", email: "three@email.com", password: "three"}
];

public type CreatedUser record {|
    *http:Created;
    User body;
|};

public type ConflictError record {|
    *http:Conflict;
    ErrorMsg body;
|};

public type InvalidUserId record {|
    *http:NotFound;
    ErrorMsg body;
|};

public type ErrorMsg record {|
    string errmsg;
|};