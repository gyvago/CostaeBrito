CREATE OR REPLACE PROCEDURE "AD_PROCARQ_CST"(P_CODUSU    NUMBER, -- C�digo do usu�rio logado
                                             P_IDSESSAO  VARCHAR2, -- Identificador da execu��o. Serve para buscar informa��es dos par�metros/campos da execu��o.
                                             P_QTDLINHAS NUMBER, -- Informa a quantidade de registros selecionados no momento da execu��o.
                                             P_MENSAGEM  OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela ser� exibida como uma informa��o ao usu�rio.
                                             ) AS
  FIELD_NUMCOTACAO NUMBER;

  V_COUNT_CODPROD INT;
  --V_CODPROD           INT;

  v_CODPROD INT;
  V_CODVOL  VARCHAR2(2);

  v_CODLOCALPADRAO INT;

  c int := 0;
  
  v_count int :=0;

BEGIN

  -- Os valores informados pelo formul�rio de par�metros, podem ser obtidos com as fun��es:
  --     ACT_INT_PARAM
  --     ACT_DEC_PARAM
  --     ACT_TXT_PARAM
  --     ACT_DTA_PARAM
  -- Estas fun��es recebem 2 argumentos:
  --     ID DA SESS�O - Identificador da execu��o (Obtido atrav�s de P_IDSESSAO))
  --     NOME DO PARAMETRO - Determina qual parametro deve se deseja obter.

  FOR I IN 1 .. P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execu��o.
   LOOP
    -- A vari�vel "I" representa o registro corrente.
    -- Para obter o valor dos campos utilize uma das seguintes fun��es:
    --     ACT_INT_FIELD (Retorna o valor de um campo tipo NUM�RICO INTEIRO))
    --     ACT_DEC_FIELD (Retorna o valor de um campo tipo NUM�RICO DECIMAL))
    --     ACT_TXT_FIELD (Retorna o valor de um campo tipo TEXTO),
    --     ACT_DTA_FIELD (Retorna o valor de um campo tipo DATA)
    -- Estas fun��es recebem 3 argumentos:
    --     ID DA SESS�O - Identificador da execu��o (Obtido atrav�s do par�metro P_IDSESSAO))
    --     N�MERO DA LINHA - Relativo a qual linha selecionada.
    --     NOME DO CAMPO - Determina qual campo deve ser obtido.
    FIELD_NUMCOTACAO := ACT_INT_FIELD(P_IDSESSAO, I, 'NUMCOTACAO');
  
    for x in (select listagg(REFERENCIA, ',') refe
                from (select count(REFERENCIA), REFERENCIA
                        from (SELECT elemento(texto, 1, ';') as "ID",
                                     elemento(texto, 2, ';') REFERENCIA,
                                     elemento(texto, 3, ';') PRODUTO,
                                     elemento(texto, 4, ';') MARCA,
                                     elemento(texto, 5, ';') UNIDADE,
                                     elemento(texto, 6, ';') QUANT,
                                     elemento(texto, 7, ';') COTACAO
                                FROM (WITH clob_table(c) as (select TEXTO
                                                               from ad_cotarquivo
                                                              where numcotacao in
                                                                    (FIELD_NUMCOTACAO))
                                       SELECT level line,
                                              87 numcotacao,
                                              regexp_substr(c, '.+', 1, level) texto
                                         FROM clob_table
                                       
                                       CONNECT BY LEVEL <=
                                                  regexp_count(c, '.+')
                                        order by 2) DUAL
                                        WHERE elemento(texto, 1, ';') != 'ID'
                              )
                       group by REFERENCIA
                      having count(1) > 1)) loop
    
      if x.refe is not null then
      
        RAISE_APPLICATION_ERROR(-20101,
                                AD_FC_FORMATAHTML(P_MENSAGEM => 'Existe item repedito na planilha',
                                                  P_MOTIVO   => 'Na planilha enviada existe as referencias abaixo repeditas <br>' ||
                                                                x.refe,
                                                  P_SOLUCAO  => 'Entrar no arquivo CSV e revisar, verificando itens repetido.'));
      
      end if;
    
    end loop;
  
    for c1 in (SELECT elemento(texto, 1, ';') as "ID",
                      elemento(texto, 2, ';') REFERENCIA,
                      elemento(texto, 3, ';') PRODUTO,
                      elemento(texto, 4, ';') MARCA,
                      elemento(texto, 5, ';') UNIDADE,
                      elemento(texto, 6, ';') QUANT,
                      elemento(texto, 7, ';') COTACAO
                 FROM (WITH clob_table(c) as (select TEXTO
                                                from ad_cotarquivo
                                               where numcotacao in
                                                     (FIELD_NUMCOTACAO))
                        SELECT level line,
                               87 numcotacao,
                               regexp_substr(c, '.+', 1, level) texto
                          FROM clob_table
                        
                        CONNECT BY LEVEL <= regexp_count(c, '.+')
                         order by 2) DUAL
                         WHERE elemento(texto, 1, ';') != 'ID'
               ) loop
    
      SELECT COUNT(*)
        INTO V_COUNT_CODPROD
        FROM TGFPRO PRO
       WHERE PRO.REFFORN = c1.referencia;
    
      IF FIELD_NUMCOTACAO > 0 THEN
      
        SELECT COUNT(*)
          INTO V_COUNT_CODPROD
          FROM TGFPRO PRO
         WHERE PRO.REFFORN = c1.referencia and pro.marca = c1.marca; --P_REFFORN;
      
        IF V_COUNT_CODPROD > 0 THEN
        
          SELECT nvl(PRO.CODVOL, c1.unidade) CODVOL,
                 --SELECT nvl(PRO.CODVOL, c1.unidade),
                 NVL(PRO.CODLOCALPADRAO, 0),
                 PRO.CODPROD
            INTO v_CODVOL, v_CODLOCALPADRAO, v_CODPROD
            FROM TGFPRO PRO
           WHERE PRO.REFFORN = c1.referencia and pro.marca = c1.marca; --P_REFFORN;
        
        ELSE
        
          --v_CODPROD := (SELECT MAX(PRO.CODPROD)+1 FROM TGFPRO PRO);
        
          SELECT MAX(PRO.CODPROD) + 1 INTO v_CODPROD FROM TGFPRO PRO;
        
          --SELECT MAX(PRO.CODPROD)+1 FROM TGFPRO PRO;
        
          /*INSERT TGFPRO (.....)
          
          VALUES (v_CODPROD, ......);*/
        
          INSERT INTO TGFPRO
            (CODPROD,                               
             DESCRPROD,
             COMPLDESC,
             CARACTERISTICAS,
             REFERENCIA,
             CODGRUPOPROD,
             CODVOL,
             MARCA,
             LOCALIZACAO,
             CODIPI,
             CLASSUBTRIB,
             CODFORMPREC,
             MARGLUCRO,
             MULTIPVENDA,
             DECCUSTO,
             DECVLR,
             DECQTD,
             COMGER,
             COMVEND,
             DESCMAX,
             PESOBRUTO,
             PESOLIQ,
             MEDAUX,
             PRAZOVAL,
             AGRUPMIN,
             QTDEMB,
             ALERTAESTMIN,
             PROMOCAO,
             TEMICMS,
             TEMISS,
             TEMIPIVENDA,
             TEMIPICOMPRA,
             TEMIRF,
             PERCIRF,
             TEMINSS,
             PERCINSS,
             REDBASEINSS,
             USOPROD,
             ORIGPROD,
             TIPSUBST,
             CODICMSFAST,
             TIPLANCNOTA,
             TIPCONTEST,
             CODTAB,
             CODCTACTB,
             IMAGEM,
             ATIVO,
             ESTMAX,
             ESTMIN,
             APRESDETALHE,
             SELECIONADO,
             TITCONTEST,
             LISCONTEST,
             CODMOEDA,
             GRUPOICMS,
             PERCAUMENTCUSTO,
             LOCAL,
             DTALTER,
             USALOCAL,
             HOMEPAGE,
             CODCTACTB2,
             CODCTACTB3,
             TEMPOSERV,
             ENDIMAGEM,
             CODUSU,
             CODPARCFORN,
             CODVOLCOMPRA,
             CODPRODROI,
             GRUPODESCPROD,
             REFFORN,
             HRDOBRADA,
             ICMSGERENCIA,
             CODNAT,
             CODCENCUS,
             CODPROJ,
             M3,
             TEMCIAP,
             IMPLAUDOLOTE,
             CODGAR,
             CODCTACTB4,
             DIMENSOES,
             PERCQUEBRATEC,
             CODFILTRO,
             CODGENERO,
             CODLST,
             PADRAO,
             ENDMODROTULO,
             NATUREZAOPERDES,
             CNAE,
             SOLCOMPRA,
             CONFERE,
             REMETER,
             MOTIVOINCEXC,
             ARREDPRECO,
             TEMCOMISSAO,
             COMPONOBRIG,
             FATTOTAL,
             NOMETAB,
             AP1RCTEGO,
             CALCULOGIRO,
             REDBASEIRF,
             ALTURA,
             LARGURA,
             ESPESSURA,
             UNIDADE,
             CODFORMAPONTA,
             CODCOS,
             CONFCEGAPESO,
             ORDCALCCUSTPROD,
             REGRAWMS,
             GRUPOPIS,
             GRUPOCOFINS,
             GRUPOCSSL,
             CSTIPIENT,
             CSTIPISAI,
             STATUSINCEXC,
             UTILIZAWMS,
             BALANCA,
             CODPAIS,
             RENDIMENTO,
             OBSETIQUETA,
             CODANP,
             CODAUTCODIF,
             CODPRODAGRUPAPT,
             CODPRODAGRUPAPTENC,
             CULTURA,
             CIENTIFICO,
             CLASSEAGT,
             GRUPOQUIMICO,
             CLASSETOX,
             PRINCATIVO,
             FORMULACAO,
             CONCENTRACAO,
             MODOAPLIC,
             EPOCAAPLIC,
             MANEJOINT,
             DOSAGEM,
             VOLDOSAGEM,
             DOSAGEMPOR,
             VOLDOSAGEMPOR,
             RENDIMENTOPR,
             RECEITUARIO,
             EXIGEBENEFIC,
             TIPOCLASSEAGT,
             TIPOGRUPOQUIMICO,
             TIPOPRINCATIVO,
             TIPOCLASSETOX,
             GRUPOTRANSG,
             GERAPLAPROD,
             APLICACAO,
             INTERVALO,
             CARENCIA,
             RENDIMENTOHA,
             PRODUTONFE,
             TIPGTINNFE,
             NCM,
             CODVOLPLAN,
             DESCMAXFLEX,
             ACRESCMAX,
             FLEX,
             NUMITEMREA,
             IMPRIMIR,
             CONFIRMAIMP,
             APURAPRODEPE,
             INDESPPRODEPE,
             QTDNFLAUDOSINT,
             CODTRIBMUNISS,
             TIPCONTESTWMS,
             LISTALPM,
             ONEROSO,
             REFMERCMED,
             TERMOLABIL,
             TEMPMINIMA,
             TEMPMAXIMA,
             CONTROLADO,
             IDENPORTARIA,
             IDENOTC,
             IDENCORRELATO,
             IDENCOSME,
             PRODFALTA,
             CODFAB,
             STATUSMED,
             CODCPR,
             SEQSPR,
             SEQSCA,
             SEQSTE,
             CODCAT,
             CODTER,
             CODPAT,
             MVAAJUSTADO,
             INFPUREZA,
             FABRICANTE,
             USASTATUSLOTE,
             TAMLOTE,
             TAMSERIE,
             UNIDMINARMAZ,
             ORIGEMFAT,
             USACODBARRASQTD,
             MD5PAF,
             VALCAPM3,
             QTDPECAFRAC,
             UTILORDCORTE,
             CODPRODPERDA,
             DESCRUTILBEM,
             IMPORDEMCORTE,
             PERCTROCA,
             CORFONTCONSPRECO,
             CORFUNDOCONSPRECO,
             CODVOLRES,
             CODAREASEP,
             IDENTIMOB,
             UTILIMOB,
             TEMCREDPISCOFINSDEPR,
             CODPRODINNATURA,
             UTILSMARTCARD,
             RECUPAVARIA,
             CONVERVOL,
             LASTRO,
             CAMADAS,
             ORDEMMEDIDA,
             ALIQICMSINTEFD,
             CODREGMAPA,
             APRESFORM,
             CODBARCOMP,
             TEMMEDICAO,
             CODFILTROREQ,
             NATBCPISCOFINS,
             CONTARPORPESO,
             CODLOCALPADRAO,
             PERMCOMPPROD,
             CODEXNCM,
             QTDCST,
             DIASCST,
             PERCTOLVARCST,
             QTDPEDPEND,
             LEADTIME,
             VALCBGLOBAL,
             USAPONTOS,
             CODRFA,
             PERCROYALTY,
             INTEGRAECONECT,
             SHELFLIFE,
             SHELFLIFEMIN,
             DTVALDIF,
             ENQREINTEGRA,
             DIASEXPEDICAO,
             CODBARBALANCA,
             PERCCMTNAC,
             PERCCMTIMP,
             NOTIFCONF,
             USASERIEFAB,
             TIPSERNFE,
             VENCOMPINDIV,
             EXCLUIRCONF,
             PRODUZAUT,
             USAIMPAGRUPMIN,
             RASTRESTOQUE,
             IMPETIQCONF,
             VLRCOMERC,
             VLRPARCIMPEXT,
             CODFCI,
             CODATIVREINTEGRA,
             SERVPARAINDUST,
             CAT1799SPRES,
             ALIQNAC,
             ALIQIMP,
             DESCRPRODNFE,
             GERACUSTCOMPSEG,
             ESTSEGQTD,
             ESTSEGDIAS,
             DTALTERESQ,
             LOTECOMPRAS,
             ESTMAXQTD,
             ESTMAXDIAS,
             DTALTEREMQ,
             DESVIOMAX,
             ARREDAGRUP,
             APLICASAZO,
             LOTECOMPMINIMO,
             AGRUPCOMPMINIMO,
             USASERIESEPWMS,
             TOPFATURCON,
             SERFATURCON,
             CODGPROD,
             CODPARCCONSIG,
             USALOTEDTVAL,
             USALOTEDTFAB,
             EXIGELASTROCAMADAS,
             FIXOAGENDA,
             EXIBCOMPEXPKIT,
             TIPORECEITAMOD21,
             NATEFDCONTM410M810,
             CODPRODSUBST,
             DTSUBST,
             CODCOMP,
             PERCTOLPESOMAIOR,
             PERCTOLPESOMENOR,
             CODVOLPESOVAR,
             USACONTPESOVAR,
             PERCTOLPESOMAIORSEP,
             PERCTOLPESOMENORSEP,
             PCT_BF,
             PRZ_BF,
             CONTROLMEDIC,
             DECVLRENT,
             PERCCMTFED,
             PERCCMTEST,
             PERCCMTMUN,
             DESCVENCONSUL,
             GRUPOICMS2,
             MVAPADRAO,
             ALIQGERAL,
             CODPRODSUBKIT,
             CODCONFKIT,
             TIPOKIT,
             CODENQIPIENT,
             CODENQIPISAI,
             CODESPECST,
             VISIVELAPPOS,
             UTILIZAENDFLUT,
             MAXMULTECONECT,
             CODVTP,
             QTDIDENTIF,
             TIPOIDENTIF,
             MODETIQSEPWMS,
             IMPETIQSEPWMS,
             NROPROCESSO,
             TIPOSN,
             ARMAZELOTE,
             CODSERVTELECOM,
             TEMRASTROLOTE,
             CODANVISA,
             DESCRANP,
             PERCMISTGLP,
             TIPOCONTAGEM,
             CODMARCA,
             PERCMISTGNN,
             PERCMISTGNI,
             VLRPARTIDAGLP,
             CODCTACTBEFD,
             CODCPRB,
             COMERCIALIZACAOAGRI,
             OBRACONSTCIVIL,
             CLASSIFCESSAOOBRA,
             PERCVLBRUTAPOSENT15ANOS,
             PERCVLBRUTAPOSENT20ANOS,
             PERCVLBRUTAPOSENT25ANOS,
             QTDAGRUPAMENTOMTZ,
             TIPOINSSESPECIAL,
             PERCINSSESPECIAL,
             CALCDIFAL,
             CODFILTROCTA,
             INDESCALA,
             CNPJFABRICANTE,
             CODBENEFNAUF,
             CODAGREGACAO,
             CODIDCNAE,
             FORCAEXPECONECT,
             REGISTRARPESO,
             DESVIOMAXTOLCONFSEP,
             DESVIOMINTOLCONFSEP,
             SERVPRESTTER,
             FRAGMENTALOTE,
             PERCREDBASEICMSEFET,
             MOTISENCAOANVISA,
             CONSPRODCAT42,
             NUVERSAOIMG,
             INTEGRAFOX,
             NUVERSAO,
             CODNBS,
             TIPOITEMSPED,
             INCPESOBRUTO,
             INCPESOLIQUIDO,
             NURFE,
             MVAORIGINALDRCST,
             TAMANHOMEDIOPECA,
             IDGRADE,
             AD_ORIPAR,
             AD_DATIMP,
             AD_CODUSUIMP,
             AD_IMPORT)
          VALUES
            (v_CODPROD,
             c1.produto,
             null,
             null,
             null,
             '9000000',
             REPLACE(c1.unidade, 'UNIDADE', 'UN'),
             C1.MARCA,
             null,
             null,
             '12',
             '1',
             null,
             null,
             null,
             '2',
             '0',
             null,
             null,
             null,
             '0',
             '0',
             null,
             null,
             null,
             null,
             'S',
             'N',
             'S',
             'N',
             'N',
             'N',
             'N',
             null,
             'N',
             '0',
             '0',
             'C',
             '0',
             'N',
             null,
             'A',
             'N',
             null,
             null,
             EMPTY_BLOB(),
             'S',
             null,
             null,
             'N',
             null,
             null,
             null,
             '2',
             null,
             null,
             'N',
             SYSDATE,
             'S',
             null,
             null,
             null,
             null,
             null,
             '0',
             null,
             '0',
             null,
             null,
             c1.referencia,
             'N',
             'S',
             '0',
             '0',
             '0',
             null,
             'N',
             'N',
             null,
             null,
             'N',
             null,
             null,
             null,
             null,
             'S',
             null,
             null,
             null,
             'S',
             'N',
             'N',
             null,
             '0',
             'S',
             'N',
             null,
             null,
             'N',
             'E',
             null,
             null,
             null,
             null,
             'MM',
             null,
             null,
             'N',
             null,
             'O',
             'TODOS',
             'TODOS',
             'TODOS',
             '49',
             '-1',
             null,
             'N',
             'N',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             'N',
             'N',
             null,
             null,
             null,
             null,
             null,
             'N',
             null,
             null,
             null,
             null,
             '0',
             '2',
             '12345678',
             null,
             null,
             null,
             'S',
             null,
             '0',
             'N',
             null,
             null,
             '0',
             null,
             'N',
             'N',
             'N',
             'N',
             'N',
             null,
             null,
             'N',
             null,
             null,
             'N',
             'N',
             'N',
             null,
             '0',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             '0',
             'N',
             null,
             'N',
             null,
             null,
             null,
             'E',
             'N',
             null,
             'N',
             'N',
             'N',
             null,
             null,
             'N',
             '0',
             null,
             null,
             null,
             null,
             null,
             null,
             'N',
             null,
             'N',
             'N',
             null,
             null,
             null,
             null,
             null,
             null,
             'S',
             'N',
             'N',
             null,
             'D',
             'N',
             null,
             'S',
             '0',
             '0',
             '0',
             '100',
             null,
             null,
             'N',
             'N',
             null,
             null,
             'N',
             null,
             null,
             'X',
             'N',
             null,
             'N',
             '0',
             '0',
             null,
             null,
             null,
             null,
             null,
             'N',
             'S',
             'N',
             'S',
             null,
             null,
             null,
             null,
             'N',
             'N',
             null,
             null,
             null,
             'N',
             '0',
             null,
             null,
             null,
             '0',
             null,
             null,
             '0',
             '0,5',
             'S',
             '0',
             '0',
             'N',
             null,
             null,
             null,
             null,
             null,
             null,
             'S',
             'S',
             'T',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             '0',
             '0',
             '0',
             'N',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             'N',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             'N',
             null,
             'N',
             null,
             null,
             null,
             'D',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             'S',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             'N',
             null,
             null,
             null,
             null,
             null,
             '52',
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             SYSDATE,
             0,
             'S');
        
        END IF;
      
        commit;
      
        --IF (v_CODPROD > 0) THEN
      
        /*SELECT PAP.CODPARC, PAP.CODPROPARC, PAP.CODPROD, PRO.CODVOL, NVL(PRO.CODLOCALPADRAO,0) INTO v_PAP_CODPARC, v_PAP_CODPROPARC, v_PAP_CODPROD, v_CODVOL, v_CODLOCALPADRAO
        --SELECT PAP.CODPARC, PAP.CODPROPARC, PAP.CODPROD INTO v_PAP_CODPARC, v_PAP_CODPROPARC, v_PAP_CODPROD
        FROM TGFPAP PAP, TGFPRO PRO
        WHERE
        PAP.CODPROD = PRO.CODPROD AND
        PAP.CODPARC = P_FORNECEDOR AND
        PAP.CODPROPARC = P_CODPROPARC;
        --PAP.CODPROD = 
        
        SELECT COUNT(*) INTO v_COUNT
        FROM TGFITC ITC
        WHERE
        ITC.NUMCOTACAO = P_COTACAO AND
        ITC.CODPROD = v_PAP_CODPROD AND
        ITC.CODPARC = 0 AND
        ITC.CONTROLE = ' ' AND
        ITC.CODLOCAL = v_CODLOCALPADRAO AND
        ITC.CABECALHO = 'S' AND
        ITC.DIFERENCIADOR = 0;
        
        IF v_COUNT = 0 THEN
        
        */
      
        select count(1)
          into v_count
          from tgfitc i
         where i.numcotacao = FIELD_NUMCOTACAO
           and i.codprod = v_CODPROD;
      
        if v_count = 0 then
        
          INSERT INTO TGFITC
            (NUMCOTACAO,
             CODPROD,
             CODPARC,
             CONTROLE,
             CODLOCAL,
             CODVOL,
             PRECO,
             QTDCOTADA,
             RESULTCOT,
             QUALPROD,
             CONFIABFORN,
             QUALATEND,
             MELHOR,
             SITUACAO,
             CODTIPVENDA,
             CABECALHO,
             DIFERENCIADOR,
             RESPMINCOT,
             CODPARCDEST,
             STATUSPRODCOT,
             TIPOCOLPRECO,
             DTCOLETAPRECO,
             AD_NROORC,
             AD_IMPORT,
             AD_DATIMP,
             AD_CODUSUIMP)
          VALUES
            (FIELD_NUMCOTACAO,
             v_CODPROD,
             0,
             ' ',
             0,
             NVL(v_CODVOL,'UN'),
             '',
             c1.quant,
             0,
             0,
             0,
             0,
             'N',
             'P',
             0,
             'S',
             0,
             1,
             0,
             'O',
             'MANUAL',
             SYSDATE,
             0,
             'S',
             SYSDATE,
             STP_GET_CODUSULOGADO);
        END IF;
      end if;
    
    end loop;
  
  -- <ESCREVA SEU C�DIGO AQUI (SER� EXECUTADO PARA CADA REGISTRO SELECIONADO)> --
  
  END LOOP;

  -- <ESCREVA SEU C�DIGO DE FINALIZA��O AQUI> --

END;
/
