SET SERVEROUTPUT ON SIZE 1000000

declare
  --
  cursor c_dados is
  SELECT object_name,
         object_type,
         DECODE(object_type, 'PACKAGE', 1,
                             'PACKAGE BODY', 2,
                             'FUNCTION', 3,
                             'PROCEDURE', 4,
                             'TRIGGER', 5,
                             'VIEW', 6, 6) AS recompile_order
    FROM user_objects
   WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE', 'TRIGGER', 'VIEW')
     AND status != 'VALID'
   ORDER BY 3;
  --
BEGIN
  --
  FOR cur_rec IN c_dados LOOP
    exit when c_dados%notfound or (c_dados%notfound) is null;
    BEGIN
      IF cur_rec.object_type = 'PACKAGE BODY' THEN
        EXECUTE IMMEDIATE 'ALTER PACKAGE "' || cur_rec.object_name || '" COMPILE BODY';
      ElSE
        EXECUTE IMMEDIATE 'ALTER ' || cur_rec.object_type || ' "' || cur_rec.object_name || '" COMPILE';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line(cur_rec.object_type || ' : ' || cur_rec.object_name);
    END;
  END LOOP;
  --
END;
/
