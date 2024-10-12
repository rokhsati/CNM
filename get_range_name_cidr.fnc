CREATE OR REPLACE FUNCTION get_range_name_cidr(ip_address IN VARCHAR2) RETURN VARCHAR2 IS
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

    -- Function to check if IP is in a given CIDR range
    FUNCTION is_ip_in_cidr(ip_num IN NUMBER, cidr IN VARCHAR2) RETURN BOOLEAN IS
        v_ip VARCHAR2(15);
        v_prefix_length NUMBER;
        v_base_ip VARCHAR2(15);
        v_base_ip_num NUMBER;
        v_mask NUMBER;
    BEGIN
        -- Split the CIDR notation into base IP and prefix length
        v_ip := SUBSTR(cidr, 1, INSTR(cidr, '/') - 1);
        v_prefix_length := TO_NUMBER(SUBSTR(cidr, INSTR(cidr, '/') + 1));

        -- Convert the base IP address to a numeric value
        v_base_ip_num := ip_to_num(v_ip);
        
        -- Calculate the subnet mask
        v_mask := POWER(2, 32) - POWER(2, 32 - v_prefix_length);

        -- Check if IP falls within the network range
        RETURN (ip_num AND v_mask) = (v_base_ip_num AND v_mask);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE; -- Return false in case of any error
    END;

BEGIN
    -- Convert the provided IP address to its numeric representation
    DECLARE
        v_ip_num NUMBER := ip_to_num(ip_address);
    BEGIN
        -- Query to find the range name based on the CIDR ranges
        FOR r IN (SELECT range_cidr, range_name FROM ip_ranges) LOOP
            IF is_ip_in_cidr(v_ip_num, r.range_cidr) THEN
                v_range_name := r.range_name;
                EXIT;
            END IF;
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            v_range_name := NULL; -- Handle any unforeseen exceptions
    END;

    RETURN v_range_name;
END get_range_name_cidr;
