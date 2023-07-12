PL/SQL Developer Test script 3.0
70
-- Created on 21/05/2022 by GYVAG 
declare
  -- Local variables here
  i integer;
begin
  -- Test statements here
  for c1 in (select gg.codemp,
                    gg.codprod,
                    gg.codvol,
                   -- gg.controle,
                    gg.codlocal,
                    sum(gg.qtdest) qtdest
               from gg_inventario__emp_04_v2 gg
              WHERE /*GG.CODPROD = 100186360 and*/
              exists (select 1 from tgfpro pro where pro.codprod = gg.codprod)
          and gg.codemp = 4
              group by gg.codemp,
                       gg.codprod,
                       gg.codvol,
                       --gg.controle,
                       gg.codlocal) loop
  
    MERGE INTO TGFCTE C
    USING (SELECT trunc(sysdATE) AS DTCONTAGEM,
                  c1.codemp AS CODEMP,
                  c1.codlocal AS CODLOCAL,
                  c1.codprod AS CODPROD,
                  ' ' AS CONTROLE,
                  c1.codvol AS CODVOL,
                  0 AS CODPARC,
                  'P' AS TIPO,
                  2 AS SEQUENCIA
             FROM DUAL) CTE
    ON (C.DTCONTAGEM = CTE.DTCONTAGEM AND C.CODEMP = CTE.CODEMP AND C.CODLOCAL = CTE.CODLOCAL AND C.CODPROD = CTE.CODPROD AND C.CONTROLE = CTE.CONTROLE AND C.CODVOL = CTE.CODVOL AND C.CODPARC = CTE.CODPARC AND C.TIPO = CTE.TIPO AND C.SEQUENCIA = CTE.SEQUENCIA)
    WHEN MATCHED THEN
      UPDATE
         SET C.QTDEST      = C.QTDEST + c1.qtdest,
             C.QTDESTUNCAD = C.QTDESTUNCAD + c1.qtdest
    WHEN NOT MATCHED THEN
      INSERT
        (DTCONTAGEM,
         CODEMP,
         CODLOCAL,
         CODPROD,
         CONTROLE,
         CODVOL,
         CODPARC,
         TIPO,
         SEQUENCIA,
         QTDEST,
         QTDESTUNCAD,
         DTVAL,
         DTFABRICACAO)
      VALUES
        (trunc(sysdate),
         c1.codemp,
         c1.codlocal,
         c1.codprod,
         ' ',
         'UN',
         0,
         'P',
         2,
         c1.qtdest,
         c1.qtdest,
         NULL,
         NULL);
  
  end loop;
end;
0
0
