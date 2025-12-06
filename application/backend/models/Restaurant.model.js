// models/Restaurant.model.js
const {
  GetCommand,
  PutCommand,
  ScanCommand,
  UpdateCommand,
  DeleteCommand
} = require("@aws-sdk/lib-dynamodb");

const bcrypt = require("bcryptjs");
const { v4: uuidv4 } = require("uuid");

const TABLE = "Restaurants";

// Convert DynamoDB item into object with methods
function wrapRestaurant(item) {
  if (!item) return null;

  return {
    ...item,

    // match Mongoose comparePassword
    async comparePassword(password) {
      return bcrypt.compare(password, this.Password);
    }
  };
}

module.exports = {
  async find() {
    const data = await global.db.send(new ScanCommand({ TableName: TABLE }));
    return (data.Items || []).map(wrapRestaurant);
  },

  async findById(id) {
    const result = await global.db.send(
      new GetCommand({ TableName: TABLE, Key: { id } })
    );
    return wrapRestaurant(result.Item);
  },

  async findOne(filter) {
    // Only supports Email filter
    if (filter.Email) {
      const data = await global.db.send(new ScanCommand({
        TableName: TABLE,
        FilterExpression: "#E = :email",
        ExpressionAttributeNames: { "#E": "Email" },
        ExpressionAttributeValues: { ":email": filter.Email }
      }));

      if (data.Items && data.Items.length > 0) {
        return wrapRestaurant(data.Items[0]);
      }
    }
    return null;
  },

  async create(data) {
    const id = uuidv4();
    const hashedPassword = await bcrypt.hash(data.Password, 10);

    const item = {
      id,
      Name: data.Name,
      Email: data.Email,
      Password: hashedPassword,
      Commercial_Num: data.Commercial_Num,
      Phone: data.Phone,
      Location: data.Location,
      img: data.img || ""
    };

    await global.db.send(
      new PutCommand({
        TableName: TABLE,
        Item: item
      })
    );

    return wrapRestaurant(item);
  },

  async update(id, updates) {
    const expression = [];
    const names = {};
    const values = {};

    for (const key of Object.keys(updates)) {
      expression.push(`#${key} = :${key}`);
      names[`#${key}`] = key;
      values[`:${key}`] = updates[key];
    }

    await global.db.send(new UpdateCommand({
      TableName: TABLE,
      Key: { id },
      UpdateExpression: "SET " + expression.join(", "),
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      ReturnValues: "ALL_NEW"
    }));

    return this.findById(id);
  },

  async delete(id) {
    await global.db.send(
      new DeleteCommand({
        TableName: TABLE,
        Key: { id }
      })
    );
    return true;
  }
};
