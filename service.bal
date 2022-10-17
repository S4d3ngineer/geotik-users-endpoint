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
    # + user - record of type User
    # + return - if successful returns posted user record in response body
    resource function post users(@http:Payload User user) returns CreatedUser|ConflictingUserIdError {
        boolean isIdTaken = usersTable.hasKey(user.id);
        if isIdTaken {
            return {
                body: {
                    errmsg: string `User id ${user.id} already exists `
                }
            };
        }
        usersTable.add(user);
        return <CreatedUser>{body: user};
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

public type ConflictingUserIdError record {|
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