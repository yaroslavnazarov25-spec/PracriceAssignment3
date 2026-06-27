1) A function returns a value, while procedure may or may no return a value. 
   A function can be called via SELECT, unlike a procedure. 
   A procedure supports COMMIT/ROLLBACK, unlike a function.
2) No, a trigger cannot be executed manually. It is automatically called when a specified event, such as INSERT, UPDATE, or DELETE, is used. 
   This ensures that the trigger logic is executed when the required event happens.
3) Storing business logic in the database improves data consistency, reduces code repeats
   and allows multiple applications to share the same rules. However, it can make the database
   more complex, harder to maintain and reduce portability between different management systems.
