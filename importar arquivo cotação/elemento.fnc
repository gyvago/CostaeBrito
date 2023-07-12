CREATE OR REPLACE FUNCTION elemento( p_string VARCHAR2
                 , p_elemento PLS_INTEGER
                 , p_separador VARCHAR2
                 ) RETURN VARCHAR2 AS
  v_string VARCHAR2(5000);
BEGIN
  v_string := p_string || p_separador;
  FOR i IN 1 .. p_elemento - 1
  LOOP
    v_string := SUBSTR(v_string,INSTR(v_string,p_separador)+LENGTH(p_separador));
  END LOOP;

  RETURN SUBSTR(v_string,1,INSTR(v_string,p_separador)-1);
END elemento;
/
