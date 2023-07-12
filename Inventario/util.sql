create table GG_INVENTARIO
(
  codemp   NUMBER(5) not null,
  codprod  NUMBER(10) not null,
  codvol   VARCHAR2(2) not null,
  controle VARCHAR2(100) not null,
  codlocal NUMBER(10) not null,
  qtdest   FLOAT
);

select rowid, gg.* from gg_inventario gg WHERE GG.CODPROD = 100182793;
SELECT rowid, CTE.*
  FROM TGFCTE CTE
 WHERE CTE.CODEMP = 3
   AND CTE.CODPROD = 100181052 ;
   
delete from gg_inventario gg;
select rowid, gg.* from gg_inventario gg;

SELECT TGFCTE.CODEMP       AS CODEMP,
       TGFCTE.CODLOCAL     AS CODLOCAL,
       TGFCTE.CODPARC      AS CODPARC,
       TGFCTE.CODPROD      AS CODPROD,
       TGFCTE.CODVOL       AS CODVOL,
       TGFCTE.CONTROLE     AS CONTROLE,
       TGFCTE.DHCONFBOMI   AS DHCONFBOMI,
       TGFCTE.DTCONTAGEM   AS DTCONTAGEM,
       TGFCTE.DTFABRICACAO AS DTFABRICACAO,
       TGFCTE.DTVAL        AS DTVAL,
       TGFCTE.ERROCONFBOMI AS ERROCONFBOMI,
       TGFCTE.NOMEARQBOMI  AS NOMEARQBOMI,
       TGFCTE.NUIVT        AS NUIVT,
       TGFCTE.QTDEST       AS QTDEST,
       TGFCTE.QTDESTUNCAD  AS QTDESTUNCAD,
       TGFCTE.SEQUENCIA    AS SEQUENCIA,
       TGFCTE.TIPO         AS TIPO
  FROM TGFCTE /*SQL_92_JOINED_TABLES*/
 WHERE ( TGFCTE.CONTROLE = '752NWX01WB')
