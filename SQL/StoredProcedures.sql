/* GetAllProducts */
CREATE OR ALTER PROCEDURE GetAllProducts
AS
SELECT c.Name Category, p.Name Product, Price, InStock, Popularity
FROM Products p
    INNER JOIN Categories c
    ON p.CategoryId = c.Id
GO

EXEC GetAllProducts
GO


/* GetProductDetails & Popularity +1 */
CREATE OR ALTER PROCEDURE GetProductDetails
    (@ProcuctId int)
AS
SELECT c.Name Category, p.Name Product, Price, InStock, Popularity
FROM Products p
    INNER JOIN Categories c
    ON p.CategoryId = c.Id
WHERE p.Id = @ProcuctId
UPDATE Products 
	SET Products.Popularity +=1
	WHERE Products.Id = @ProcuctId
GO


/* ListProductsByCategory */
CREATE OR ALTER PROCEDURE ListProductsByCategory
    (@InStock int)
AS
SELECT c.Name AS Kategori, p.Name Produkt, p.Price Pris, p.Popularity Popularitet
FROM Products p
    INNER JOIN Categories c ON p.CategoryId = c.Id

WHERE p.InStock = @InStock
    OR p.InStock = 1

GROUP BY c.Name, p.Name, p.Price, p.Popularity
ORDER BY c.Name, p.Popularity DESC
GO

EXEC ListProductsByCategory 0
GO


/* CreateCart & Return CartId */
CREATE OR ALTER PROCEDURE CreateCart
    @CustomerId int
AS
BEGIN
    INSERT INTO Carts
        (CustomerId)
    VALUES
        (@CustomerId)
    RETURN SCOPE_IDENTITY()
END
    GO


DECLARE @CartIdOut int;
EXEC @CartIdOut = CreateCart 2
SELECT @CartIdOut AS CartId
GO

/* Delete carts older than 14 days */
CREATE OR ALTER PROCEDURE ClearOldCarts
AS
BEGIN
    DELETE FROM Carts
    WHERE (DATEDIFF(WEEK, DateTimeCreated, GETDATE())) >0
END
GO

EXEC ClearOldCarts
GO

SELECT *
FROM Carts;
GO


/* Inser into cart */
CREATE OR ALTER PROCEDURE InsertIntoCart
    (@CartId int,
    @ProductId int,
    @Amount int)
AS
BEGIN
    /* existing produkt */
    IF EXISTS
    (SELECT ProductId
    FROM Products_Cart pc
    WHERE pc.Id = @CartId AND pc.ProductId = @ProductId)
    
    UPDATE Products_Cart
    SET Products_Cart.Amount += @Amount
    WHERE Products_Cart.Id = @CartId AND Products_Cart.ProductId = @ProductId

    ELSE

    /* new product */
    INSERT INTO Products_Cart
        (CartId, ProductId, Amount)
    VALUES
        (@CartId, @ProductId, @Amount)
END
    GO

SELECT *
FROM Products_Cart GO
EXEC InsertIntoCart  1, 2, -5
GO
SELECT *
FROM Products_Cart
WHERE CartId = 1
GO


/* GetCart */
CREATE OR ALTER PROCEDURE GetCart
    (@CartId int)
AS
BEGIN
    SELECT p.Name
    FROM Carts c
        INNER JOIN Products p ON c.ProductId = p.Id
    WHERE c.Id = @CartId;
END
    GO
EXEC GetCart 10

SELECT *
FROM Carts
GO
--  En order skapas till kunden
-- Artikeln reserveras i lager
--  Varukorgen tas bort
--  Ordernummer returneras
/* Checkout cart */
CREATE OR ALTER PROCEDURE CheckoutCart
    (@CustomerId int)
AS
BEGIN
    -- create order and insert customer id
    INSERT INTO Orders
        (CustomerId)
    VALUES
        (@CustomerId)

    -- insert cart data
    INSERT INTO Orders
        (ProductId,
        Amount,
        Price
        )
    SELECT ProductId,
        Amount,
        Price
    FROM Products_Cart
    WHERE Products_Cart.CartId = @CustomerId

    -- insert customer data
    INSERT INTO Orders
        (
        CustomerName,
        CustomerStreet,
        CustomerZip,
        CustomerCity,
        CustomerPhone
        )
    SELECT
        CustomerName,
        CustomerStreet,
        CustomerZip,
        CustomerCity,
        CustomerPhone
    FROM Customers
    WHERE Customers.Id = @CustomerId


    RETURN SCOPE_IDENTITY()
END
    GO