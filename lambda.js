const AWS = require('aws-sdk');
const dynamoDb = new AWS.DynamoDB.DocumentClient();

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
}

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS") {
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
    const data = await dynamoDb.get(getParams).promise();
    counterExists = !!data.Item;
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
      await dynamoDb.put(initParams).promise();
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
    const result = await dynamoDb.update(updateParams).promise();
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ count: result.Attributes.count })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Could not update the counter" })
    };
  }
};
