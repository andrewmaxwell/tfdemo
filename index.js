const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { GetCommand, PutCommand, UpdateCommand } = require("@aws-sdk/lib-dynamodb");

const dynamoDb = new DynamoDBClient();

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
}

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  if (event.httpMethod === "OPTIONS") {
    console.log("Handling OPTIONS request for CORS");
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({}),
    };
  }

  const tableName = process.env.DYNAMODB_TABLE;

  // Check if the counter exists
  const getParams = {
    TableName: tableName,
    Key: { id: "clicks" }
  };

  let counterExists = false;
  try {
    const data = await dynamoDb.send(new GetCommand(getParams));
    counterExists = !!data.Item;
    console.log("Counter exists:", counterExists);
  } catch (error) {
    console.error("Error checking if counter exists", error);
  }

  // If counter doesn't exist, create it
  if (!counterExists) {
    const initParams = {
      TableName: tableName,
      Item: {
        id: "clicks",
        count: 0
      }
    };
    try {
      await dynamoDb.send(new PutCommand(initParams));
      console.log("Initialized click counter in DynamoDB");
    } catch (error) {
      console.error("Error initializing counter", error);
      return {
        statusCode: 500,
        body: JSON.stringify({ error: "Could not initialize counter" })
      };
    }
  }

  // Increment the click counter
  const updateParams = {
    TableName: tableName,
    Key: { id: "clicks" },
    UpdateExpression: "SET #c = #c + :incr",
    ExpressionAttributeNames: { "#c": "count" },
    ExpressionAttributeValues: { ":incr": 1 },
    ReturnValues: "UPDATED_NEW"
  };

  try {
    const result = await dynamoDb.send(new UpdateCommand(updateParams));
    console.log("Counter updated successfully:", result);
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ count: result.Attributes.count })
    };
  } catch (error) {
    console.error("Error updating the counter", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Could not update the counter" })
    };
  }
};