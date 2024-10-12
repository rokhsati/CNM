CREATE OR REPLACE PACKAGE FUNCTION get_range_name(ip_address IN VARCHAR2) RETURN VARCHAR2 IS
    v_range_name VARCHAR2(100);
    
    -- Function to convert dotted IP address to a numeric value
    FUNCTION ip_to_num(ip IN VARCHAR2) RETURN NUMBER IS
        v_num NUMBER := 0;
        v_parts DBMS_OO.ODCIVARCHAR2LIST;
    BEGIN
        -- Split IP address into parts
        v_parts := DBMS_UTILITY.EXTRACT_URL_COLLECTION(ip);
        FOR i IN 1 .. v_parts.COUNT LOOP
            v_num := v_num * 256 + TO_NUMBER(v_parts(i));
        END LOOP;
        RETURN v_num;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL; -- Return null in case of any exception
    END;

BEGIN
    -- Convert the provided IP address to its numeric representation
    DECLARE
        v_ip_num NUMBER := ip_to_num(ip_address);
    BEGIN
        -- Query to find the range name
        SELECT range_name INTO v_range_name
        FROM ip_ranges
        WHERE ip_to_num(start_range) <= v_ip_num
          AND ip_to_num(end_range) >= v_ip_num;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_range_name := NULL; -- No range found for the given IP
        WHEN OTHERS THEN
            v_range_name := NULL; -- Handle any unforeseen exceptions
    END;

    RETURN v_range_name;
END get_range_name;
