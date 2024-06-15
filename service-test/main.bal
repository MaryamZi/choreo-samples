import ballerina/http;

isolated int orderId = 1000;

enum CakeKind {
    BUTTER_CAKE = "Butter Cake",
    CHOCOLATE_CAKE = "Chocolate Cake",
    TRES_LECHES = "Tres Leches"
}

enum OrderStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED
}

type OrderDetail record {|
    CakeKind item;
    int quantity;
|};

type Order record {|
    string username;
    OrderDetail[] order_items;
|};

service / on new http:Listener(8080) {
    private map<Order> orders = {
        "1025": {
            username: "mary_lou",
            order_items: [
                {
                    item: BUTTER_CAKE,
                    quantity: 1
                }
            ]
        }
    };
    private map<OrderStatus> orderStatus = {
        "1025": IN_PROGRESS
    };

    resource function get 'order/status/[string orderId]() returns OrderStatus|http:NotFound {
        lock {
            if !self.orderStatus.hasKey(orderId) {
                return {
                    body: "Order ID not found" 
                };
            }
            return self.orderStatus.get(orderId);
        }
    }

    resource function post 'order(Order 'order) returns string|http:BadRequest {
        final string newOrderId;

        error? validationStatus = validateOrder('order);
        if validationStatus is error {
            return {
                body: validationStatus.message()
            };
        }
        
        lock {
            newOrderId = orderId.toString();
            orderId += 1;
        }

        lock {
            self.orderStatus[newOrderId] = PENDING;
        }

        lock {
            self.orders[newOrderId] = 'order.cloneReadOnly();
        }

        return newOrderId;
    }

    resource function delete 'order/[string orderId]() returns http:Ok|http:Forbidden|http:NotFound {
        lock {
            if !self.orderStatus.hasKey(orderId) {
                return <http:NotFound>{
                    body: "Order ID not found" 
                };
            }

            if self.orderStatus.get(orderId) != PENDING {
                return <http:Forbidden>{
                    body: "Cannot delete an order that is not in the Pending state" 
                };
            }
            
            _ = self.orderStatus.remove(orderId);
        }


        lock {
            _ = self.orders.remove(orderId);
        }

        return http:OK;
    }
}

function validateOrder(Order newOrder) returns error? {
    var {username, order_items: items} = newOrder;

    if username.trim().length() == 0 {
        return error("Invalid username");
    }

    int totalItems = 0;

    foreach OrderDetail {quantity} in items {
        if quantity < 0 {
            return error("Invalid order quantity for item");
        }
        totalItems += quantity;
    }

    if totalItems == 0 {
        return error("Invalid order quantity");
    }
}
