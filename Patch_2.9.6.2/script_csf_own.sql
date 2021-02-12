------------------------------------------------------------------------------------------
Prompt INI Patch 2.9.6.2 - Alteracoes no CSF_OWN
------------------------------------------------------------------------------------------

insert into csf_own.versao_sistema ( ID
                                   , VERSAO
                                   , DT_VERSAO
                                   )
                            values ( csf_own.versaosistema_seq.nextval -- ID
                                   , '2.9.6.2'                         -- VERSAO
                                   , sysdate                           -- DT_VERSAO
                                   )
/

commit
/

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI Redmine #75193 - Adicionar campo EMPRESA_FORMA_TRIB.PERC_RED_IR
-------------------------------------------------------------------------------------------------------------------------------
 
declare
  vn_qtde    number;
begin
  begin
     select count(1)
       into vn_qtde 
       from all_tab_columns a
      where a.OWNER = 'CSF_OWN'  
        and a.TABLE_NAME = 'EMPRESA_FORMA_TRIB'
        and a.COLUMN_NAME = 'PERC_RED_IR'; 
   exception
      when others then
         vn_qtde := 0;
   end;	
   --   
   if vn_qtde = 0 then
      -- Add/modify columns    
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.EMPRESA_FORMA_TRIB add perc_red_ir number(5,2)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao incluir coluna "perc_red_ir" em EMPRESA_FORMA_TRIB - '||SQLERRM );
      END;
      -- 
      -- Add comments to the table   
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.EMPRESA_FORMA_TRIB.perc_red_ir is ''Percentual de Redução de IR para atividades incentivadas''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao alterar comentario de EMPRESA_FORMA_TRIB - '||SQLERRM );
      END;	  
      -- 
   end if;
   --  
   commit;
   --   
end;
/

--------------------------------------------------------------------------------------------------------------------------------------
Prompt FIM Redmine #75193 - Adicionar campo EMPRESA_FORMA_TRIB.PERC_RED_IR
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI Redmine #75651 - Atualizar tabela estrut_cte com layout 3.0 do CTe.
-------------------------------------------------------------------------------------------------------------------------------
DECLARE
  VN_INFRESPTEC NUMBER;
  VN_INFCTESUPL NUMBER;
  VN_QTD        NUMBER;
BEGIN
  --
  BEGIN
    delete from csf_own.estrut_cte
     where ID = (select c.ID
                   from versao_layout v, estrut_cte c
                  where v.id = c.versaolayout_id
                    and v.layout = 'CTE'
                    and v.versao = '3.00'
                    and c.campo = 'pICMSInterPart');
     COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
  --     
  BEGIN
    SELECT COUNT(1)
      INTO VN_QTD
      FROM csf_own.estrut_cte 
     WHERE 1=1
       AND IDENT_LINHA = 238
       AND UPPER(CAMPO) = 'VFCPUFFIM'
       AND versaolayout_id = (select max(id)
                                  from csf_own.versao_layout
                                 where layout = 'CTE'
                                   and versao = '3.00');
  EXCEPTION
    WHEN OTHERS THEN
          VN_QTD :=0;
  END;                               
  IF VN_QTD >= 1 THEN   
    BEGIN
      update csf_own.estrut_cte
         set ident_linha = ident_linha - 1
       where versaolayout_id = (select max(id)
                                  from csf_own.versao_layout
                                 where layout = 'CTE'
                                   and versao = '3.00')
         and ident_linha >= 238;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;
  --          
  BEGIN
    insert into csf_own.estrut_cte
      (ID,
       IDENT_LINHA,
       CAMPO,
       NIVEL,
       DESCR,
       DM_ELEMENTO,
       DM_TIPO,
       AR_ESTRUTCTE_ID,
       VERSAOLAYOUT_ID)
    values
      (estrutcte_seq.nextval,
       '398',
       'infRespTec',
       1,
       'Informações do Responsável Técnico pela emissão do DF-e',
       'G',
       null,
       (SELECT ID
          FROM csf_own.estrut_cte E
         WHERE E.CAMPO = 'infCte'
           AND IDENT_LINHA = 1),
       (select MAX(id)
          from csf_own.versao_layout
         where layout = 'CTE'
           and versao = '3.00'))
    RETURNING ID INTO VN_INFRESPTEC;
    COMMIT;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,
                              'FALHA NO INSERT infRespTec. ERRO:' ||
                              SQLERRM);
  END;
  IF VN_INFRESPTEC IS NOT NULL THEN
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '399',
           'CNPJ',
           2,
           'CNPJ da pessoa jurídica responsável técnica pelo sistema utilizado na emissão do documento fiscal eletrônico',
           'E',
           'N',
           VN_INFRESPTEC,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
  
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '400',
           'xContato',
           2,
           'Nome da pessoa a ser contatada',
           'E',
           'C',
           VN_INFRESPTEC,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '401',
           'email',
           2,
           'E-mail da pessoa jurídica a ser contatada',
           'E',
           'C',
           VN_INFRESPTEC,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '402',
           'fone',
           2,
           'Telefone da pessoa jurídica a ser contatada',
           'E',
           'N',
           VN_INFRESPTEC,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '403',
           'idCSRT',
           2,
           'Identificador do código de segurança do responsável técnico',
           'E',
           'N',
           VN_INFRESPTEC,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '404',
           'hashCSRT',
           2,
           'Hash do token do código de segurança do responsável técnico',
           'E',
           'C',
           VN_INFRESPTEC,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
  END IF;
  IF VN_INFRESPTEC IS NOT NULL THEN
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '405',
           'infCTeSupl',
           0,
           'Informações suplementares do CT-e',
           'G',
           NULL,
           NULL,
           (select MAX(id)
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'))
        RETURNING ID INTO VN_INFCTESUPL;
      
        COMMIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
      --
      BEGIN
        insert into csf_own.estrut_cte
          (ID,
           IDENT_LINHA,
           CAMPO,
           NIVEL,
           DESCR,
           DM_ELEMENTO,
           DM_TIPO,
           AR_ESTRUTCTE_ID,
           VERSAOLAYOUT_ID)
        values
          (estrutcte_seq.nextval,
           '406',
           'qrCodCTe',
           1,
           'Texto com o QR-Code impresso no DACTE',
           'E',
           'C',
           VN_INFCTESUPL,
           (select id
              from csf_own.versao_layout
             where layout = 'CTE'
               and versao = '3.00'));
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,
                                  'FALHA NO INSERT CNPJ. ERRO:' || SQLERRM);
      END;
  END IF;
  COMMIT;
  
  BEGIN
    UPDATE csf_own.estrut_cte
       SET IDENT_LINHA =
           (SELECT COUNT(IDENT_LINHA)
              FROM csf_own.ESTRUT_CTE
             WHERE 1=1
               AND VERSAOLAYOUT_ID =
                   (SELECT MAX(ID)
                      FROM csf_own.VERSAO_LAYOUT
                     WHERE LAYOUT = 'CTE'
                       AND VERSAO = '3.00')
            )
     WHERE UPPER(TRIM(DESCR)) = 'DS:SIGNATURE'
       AND VERSAOLAYOUT_ID = (select MAX(id)
                                from csf_own.versao_layout
                               where layout = 'CTE'
                                 and versao = '3.00');
     COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
END;
/
--------------------------------------------------------------------------------------------------------------------------------------
Prompt FIM Redmine #75651 - Atualizar tabela estrut_cte com layout 3.0 do CTe.
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI - Redmine 75658 -  Alterar tabela estrut_cte incluindo coluna DM_UTIL_CCE
-------------------------------------------------------------------------------------------------------------------------------
-- Criação da view
declare
   vn_existe number := null;
begin 
   select count(*)
     into vn_existe
     from sys.all_views v
    where v.OWNER      = 'CSF_OWN'
      and v.VIEW_NAME  = 'V_ESTRUT_CTE_CCE';
   --
   if nvl(vn_existe,0) = 0 then
      --
      execute immediate 'create or replace view CSF_OWN.v_estrut_cte_cce as select r.ident_linha, r.ar_estrutcte_id id_grupo, g.campo grupo, g.descr descr_grupo, r.id id_registro, r.campo registro, r.descr descr_registro, decode(v.layout, ''CTEOS'', ''67'', ''57'') cod_mod from CSF_OWN.estrut_cte r, CSF_OWN.estrut_cte g, versao_layout v where r.ar_estrutcte_id = g.id and r.versaolayout_id = v.id and r.dm_util_cce = 1 order by r.ident_linha';       
      --
   elsif nvl(vn_existe,0) > 0 then
      --
      execute immediate 'drop view CSF_OWN.v_estrut_cte_cce';
      execute immediate 'create or replace view CSF_OWN.v_estrut_cte_cce as select r.ident_linha, r.ar_estrutcte_id id_grupo, g.campo grupo, g.descr descr_grupo, r.id id_registro, r.campo registro, r.descr descr_registro, decode(v.layout, ''CTEOS'', ''67'', ''57'') cod_mod from CSF_OWN.estrut_cte r, CSF_OWN.estrut_cte g, versao_layout v where r.ar_estrutcte_id = g.id and r.versaolayout_id = v.id and r.dm_util_cce = 1 order by r.ident_linha';       
      --
   end if;
   -- 
exception
   when others then
      raise_application_error(-20001, 'Erro no script 75658. View V_ESTRUT_CTE_CCE. Erro: ' || sqlerrm);      
end;
/

-------------------------------------------------------------------------------------------------------------------------------
Prompt FIM - Redmine 75658 -  Alterar tabela estrut_cte incluindo coluna DM_UTIL_CCE
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
Prompt INI - Redmine #75477 -  Criação de Job Scheduler JOB_CORRIGIR_NF_CT
-------------------------------------------------------------------------------------------------------------------------------

DECLARE 
  vn_cont NUMBER;
BEGIN
  --
  -- Verifica se o Job JOB_CORRIGIR_NF_CT já foi criado, caso existir sai da rotina
  BEGIN
    SELECT COUNT(1)
      INTO vn_cont
      FROM ALL_SCHEDULER_JOBS
     WHERE JOB_NAME = 'JOB_CORRIGIR_NF_CT'
       AND ENABLED  = 'TRUE';
    EXCEPTION
      WHEN OTHERS THEN
        vn_cont := 0;
    END;
    --
    IF vn_cont = 0 THEN
        DBMS_SCHEDULER.CREATE_JOB
            (
              JOB_NAME => 'JOB_CORRIGIR_NF_CT',
              JOB_TYPE => 'STORED_PROCEDURE',
              JOB_ACTION => 'CSF_OWN.PB_CORRIGIR_PESSOA_NF_CT',
              START_DATE => SYSDATE,
              REPEAT_INTERVAL => 'SYSDATE + (((1/24)/60))',
              ENABLED => TRUE,
              COMMENTS => 'POPULA PESSOA_ID NA NF/CT QUANDO ESTIVER NULO.'
            );
     END IF;
EXCEPTION
	WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20101, 'Erro ao criar o Job - JOB_CORRIGIR_NF_CT  : '||sqlerrm);
END;
/
-------------------------------------------------------------------------------------------------------------------------------
Prompt FIM - Redmine #75477 -  Criação de Job Scheduler JOB_CORRIGIR_NF_CT
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI - Redmine 75897 - Criar nova opção de dm_st_proc valor 6 e descrição Aberto para o campo EVENTO_CTE.DM_ST_PROC
-------------------------------------------------------------------------------------------------------------------------------
declare
   vn_existe number := null;
begin 
   select count(*)
     into vn_existe
     from sys.all_tab_columns ac 
    where ac.OWNER       = 'CSF_OWN'
      and ac.TABLE_NAME  = 'EVENTO_CTE'
      and ac.COLUMN_NAME = 'DM_ST_PROC';
   --
   if nvl(vn_existe,0) = 0 then
      --
      execute immediate 'alter table CSF_OWN.EVENTO_CTE add constraint EVENTOCTE_STPROC_CK check (DM_ST_PROC in (0, 1, 2, 3, 4, 5, 6))';
      execute immediate 'comment on column CSF_OWN.EVENTO_CTE.dm_st_proc is ''Situacao do processo: 0-Nao Validado; 1-Validado; 2-Aguardando Envio; 3-Processado; 4-Erro de validacao; 5-Rejeitada; 6-Aberto''';
      --
   elsif nvl(vn_existe,0) > 0 then
      --
      execute immediate 'alter table CSF_OWN.EVENTO_CTE drop constraint EVENTOCTE_STPROC_CK';
      execute immediate 'alter table CSF_OWN.EVENTO_CTE add constraint EVENTOCTE_STPROC_CK check (DM_ST_PROC in (0, 1, 2, 3, 4, 5, 6))';
      execute immediate 'comment on column CSF_OWN.EVENTO_CTE.dm_st_proc is ''Situacao do processo: 0-Nao Validado; 1-Validado; 2-Aguardando Envio; 3-Processado; 4-Erro de validacao; 5-Rejeitada; 6-Aberto''';
      --
   end if;
   -- 
exception
   when others then
      raise_application_error(-20001, 'Erro no script 75897. Campo DM_ST_PROC. Erro: ' || sqlerrm);      
end;
/

begin 
   execute immediate 'insert into csf_own.dominio (dominio, vl, descr, id) values (''EVENTO_CTE.DM_ST_PROC'', ''6'' , ''Aberto'', csf_own.dominio_seq.nextval )';
   commit;
exception
   when dup_val_on_index then
      null;      
   when others then
      raise_application_error(-20001, 'Erro no script 75897. Domínio EVENTO_CTE.DM_ST_PROC e Valor "6". Erro: ' || sqlerrm);      
end;
/  

-------------------------------------------------------------------------------------------------------------------------------
Prompt FIM - Redmine 75897 - Criar nova opção de dm_st_proc valor 6 e descrição Aberto para o campo EVENTO_CTE.DM_ST_PROC
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI Redmine #75193 - Adicionar campo EMPRESA_FORMA_TRIB.PERC_RED_IR
-------------------------------------------------------------------------------------------------------------------------------
 
declare
  vn_qtde    number;
begin
  begin
     select count(1)
       into vn_qtde 
       from all_tab_columns a
      where a.OWNER = 'CSF_OWN'  
        and a.TABLE_NAME = 'EMPRESA_FORMA_TRIB'
        and a.COLUMN_NAME = 'PERC_RED_IR'; 
   exception
      when others then
         vn_qtde := 0;
   end;	
   --   
   if vn_qtde = 0 then
      -- Add/modify columns    
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.EMPRESA_FORMA_TRIB add perc_red_ir number(5,2)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao incluir coluna "perc_red_ir" em EMPRESA_FORMA_TRIB - '||SQLERRM );
      END;
      -- 
      -- Add comments to the table   
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.EMPRESA_FORMA_TRIB.perc_red_ir is ''Percentual de Redução de IR para atividades incentivadas''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao alterar comentario de EMPRESA_FORMA_TRIB - '||SQLERRM );
      END;	  
      -- 
   end if;
   --  
   commit;
   --   
end;
/

--------------------------------------------------------------------------------------------------------------------------------------
Prompt FIM Redmine #75193 - Adicionar campo EMPRESA_FORMA_TRIB.PERC_RED_IR
-------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI Redmine #73063 - Alterações para emissão de conhecimento de transporte.
-------------------------------------------------------------------------------------------------------------------------------
 
declare
  vn_qtde    number;
begin
  --
  begin
     select count(1)
       into vn_qtde
       from all_tables t
      where t.OWNER = 'CSF_OWN'  
        and t.TABLE_NAME = 'CONHEC_TRANSP_CCE';
   exception
      when others then
         vn_qtde := 0;
   end;	
   --   
   if vn_qtde = 0 then
      -- 
      -- Create table
      --
      BEGIN
         EXECUTE IMMEDIATE 'create table CSF_OWN.CONHEC_TRANSP_CCE (id NUMBER not null, conhectransp_id NUMBER not null, dm_st_integra NUMBER(1) default 0 not null, dm_st_proc NUMBER(2) default 0 not null, id_tag_chave VARCHAR2(54), dt_hr_evento DATE not null, tipoeventosefaz_id NUMBER, correcao VARCHAR2(1000) not null, versao_leiaute VARCHAR2(20), versao_evento VARCHAR2(20), versao_cce VARCHAR2(20), versao_aplic VARCHAR2(40), cod_msg_cab  VARCHAR2(4), motivo_resp_cab VARCHAR2(4000), msgwebserv_id_cab NUMBER, cod_msg VARCHAR2(4), motivo_resp VARCHAR2(4000), msgwebserv_id NUMBER, dt_hr_reg_evento DATE, nro_protocolo NUMBER(15), usuario_id NUMBER, xml_envio BLOB, xml_retorno BLOB, xml_proc BLOB, dm_download_xml_sic NUMBER(1) default 0 not null ) tablespace CSF_DATA';		 
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar tabela de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      -- 
      commit;
      --	  
      -- Add comments to the table   
      BEGIN
         EXECUTE IMMEDIATE 'comment on table CSF_OWN.CONHEC_TRANSP_CCE is ''Tabela de CC-e vinculada ao conhecimento de transporte''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      -- 
      -- Add comments to the columns
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.conhectransp_id is ''ID relacionado a tabela CONHEC_TRANSP''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.dm_st_integra is ''Situação de Integração: 0 - Indefinido, 2 - Integrado via arquivo texto (IN), 7 - Integração por view de banco de dados, 8 - Inserida a resposta do CTe para o ERP, 9 - Atualizada a resposta do CTe para o ERP''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --	  
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.dm_st_proc is ''Situação: 0-Não Validado; 1-Validado; 2-Aguardando Envio; 3-Processado; 4-Erro de validação; 5-Rejeitada''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.id_tag_chave is ''Identificador da TAG a ser assinada, a regra de formação do Id é: ID + tpEvento + chave do CT-e + nSeqEvento''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.dt_hr_evento is ''Data e hora do evento no formato''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.tipoeventosefaz_id is ''ID relacionado a tabela TIPO_EVENTO_SEFAZ''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.correcao is ''Correção a ser considerada, texto livre. A correção mais recente substitui as anteriores''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.versao_leiaute is ''Versão do leiaute do evento''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.versao_evento is ''Versão do evento''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.versao_cce is ''Versão da carta de correção''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.versao_aplic is ''Versão da aplicação que processou o evento''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.cod_msg_cab is ''Código do status da resposta Cabeçalho''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.motivo_resp_cab is ''Descrição do status da resposta Cabeçalho''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.msgwebserv_id_cab is ''ID relacionado a tabela MSG_WEB_SERV para cabeçalho do retorno''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.cod_msg is ''Código do status da resposta''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.motivo_resp is ''Descrição do status da resposta''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.msgwebserv_id is ''ID relacionado a tabela MSG_WEB_SERV''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.dt_hr_reg_evento is ''Data e hora de registro do evento no formato''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.nro_protocolo is ''Número do Protocolo do Evento da CC-e''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.usuario_id is ''ID relacionado a tabela NEO_USUARIO''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.xml_envio is ''XML de envio da CCe''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.xml_retorno is ''XML de retorno da CCe''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.xml_proc is ''XML de processado da CCe''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      BEGIN
         EXECUTE IMMEDIATE 'comment on column CSF_OWN.CONHEC_TRANSP_CCE.dm_download_xml_sic is ''Donwload XML pelo SIC: 0-Não; 1-Sim''';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar comentario de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;	  
      --
      -- Create/Recreate primary, unique and foreign key constraints
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CONHECTRANSPCCE_PK primary key (ID) using index tablespace CSF_INDEX';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar primary de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CTCCE_MSGWEBSERV_CAB_FK foreign key (MSGWEBSERV_ID_CAB) references CSF_OWN.MSG_WEBSERV (ID)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar foreign key de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --	  
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CTCCE_MSGWEBSERV_FK foreign key (MSGWEBSERV_ID) references CSF_OWN.MSG_WEBSERV (ID)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar foreign key de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --	  
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CTCCE_CONHECTRANSP_FK foreign key (CONHECTRANSP_ID) references CSF_OWN.CONHEC_TRANSP (ID)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar foreign key de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CTCCE_TIPOEVENTOSEFAZ_FK foreign key (TIPOEVENTOSEFAZ_ID) references CSF_OWN.TIPO_EVENTO_SEFAZ (ID)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar foreign key de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CONHECTRANSPCCE_USUARIO_FK foreign key (USUARIO_ID) references CSF_OWN.NEO_USUARIO (ID)';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar foreign key de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      -- Create/Recreate indexes 	  
      BEGIN
         EXECUTE IMMEDIATE 'create index CTCCE_MSGWEBSERV_CAB_FK_I on CSF_OWN.CONHEC_TRANSP_CCE (MSGWEBSERV_ID_CAB) tablespace CSF_INDEX';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar index de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --	  
      BEGIN
         EXECUTE IMMEDIATE 'create index CTCCE_MSGWEBSERV_FK_I on CSF_OWN.CONHEC_TRANSP_CCE (MSGWEBSERV_ID) tablespace CSF_INDEX';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar index de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --		  
      BEGIN
         EXECUTE IMMEDIATE 'create index CTCCE_CONHECTRANSP_FK_I on CSF_OWN.CONHEC_TRANSP_CCE (CONHECTRANSP_ID) tablespace CSF_INDEX';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar index de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      BEGIN
         EXECUTE IMMEDIATE 'create index CTCCE_TIPOEVENTOSEFAZ_FK_I on CSF_OWN.CONHEC_TRANSP_CCE (TIPOEVENTOSEFAZ_ID) tablespace CSF_INDEX';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar index de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      BEGIN
         EXECUTE IMMEDIATE 'create index CONHECTRANSPCCE_USUARIO_FK_I on CSF_OWN.CONHEC_TRANSP_CCE (USUARIO_ID) tablespace CSF_INDEX';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar index de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      -- Create/Recreate check constraints 	  
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CTCCE_STPROC_CK check (DM_ST_PROC in (0, 1, 2, 3, 4, 5))';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar check constraints de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.CONHEC_TRANSP_CCE add constraint CTCCE_DMSTINTEGRA_CK check (dm_st_integra IN (0,2,7,8,9))';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar check constraints de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
      -- Grant/Revoke object privileges	
      BEGIN
         EXECUTE IMMEDIATE 'grant select, insert, update, delete on CSF_OWN.CONHEC_TRANSP_CCE to CSF_WORK';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar check constraints de CONHEC_TRANSP_CCE - '||SQLERRM );
      END;
      --
   end if;
   --  
   vn_qtde := 0;   
   --
   begin   
      select count(1)
        into vn_qtde 
        from all_sequences s
       where s.SEQUENCE_OWNER = 'CSF_OWN'
         and s.SEQUENCE_NAME  = 'CONHECTRANSPCCE_SEQ';   
   exception
      when others then
         vn_qtde := 0;		 
   end;
   --  
   if vn_qtde = 0 then 
      --
      BEGIN
         -- Create sequence
         EXECUTE IMMEDIATE 'create sequence CSF_OWN.CONHECTRANSPCCE_SEQ minvalue 1 maxvalue 9999999999999999999999999999 start with 1 increment by 1 nocache';
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro ao criar sequence de CONHECTRANSPCCE_SEQ - '||SQLERRM );
      END;
      --	  
   end if;
   --  
   commit;
   --   
end;
/

begin
   --
   begin
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
                                  , '0'
                                  , 'Indefinido'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Indefinido'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
            and vl = '0';
   end;		
   --
   begin
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
                                  , '2'
                                  , 'Integrado via arquivo texto (IN)'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Integrado via arquivo texto (IN)'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
            and vl = '2';
   end;		
   --
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
                                  , '7'
                                  , 'Integração por view de banco de dados'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Integração por view de banco de dados'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
            and vl = '7';
   end;		
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
                                  , '8'
                                  , 'Inserida a resposta do CTe para o ERP'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Inserida a resposta do CTe para o ERP'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
            and vl = '8';
   end;		
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
                                  , '9'
                                  , 'Atualizada a resposta do CTe para o ERP'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Atualizada a resposta do CTe para o ERP'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_INTEGRA'
            and vl = '9';
   end;		
   --  
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_PROC'
                                  , '0'
                                  , 'Não Validado'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Não Validado'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_PROC'
            and vl = '0';
   end;	
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_PROC'
                                  , '1'
                                  , 'Validado'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Validado'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_PROC'
            and vl = '1';
   end;
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_PROC'
                                  , '2'
                                  , 'Aguardando Envio'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Aguardando Envio'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_PROC'
            and vl = '2';
   end;
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_PROC'
                                  , '3'
                                  , 'Processado'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Processado'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_PROC'
            and vl = '3';
   end;   
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_PROC'
                                  , '4'
                                  , 'Erro de validação'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Erro de validação'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_PROC'
            and vl = '4';
   end;    
   --   
   begin   
      insert into csf_own.dominio ( dominio
                                  , vl
                                  , descr
                                  , id
                                  )
                           values ( 'CONHEC_TRANSP_CCE.DM_ST_PROC'
                                  , '5'
                                  , 'Rejeitada'
                                  , csf_own.dominio_seq.nextval);
   exception
      when others then
         update csf_own.dominio
            set descr = 'Rejeitada'           
          where dominio = 'CONHEC_TRANSP_CCE.DM_ST_PROC'
            and vl = '5';
   end;   
   --
   commit;
   --     
end;
/

declare
  vn_qtde    number;
begin
  --
  begin
     select count(1)
       into vn_qtde
       from all_tab_columns c
      where c.OWNER       = 'CSF_OWN'
        and c.TABLE_NAME  = 'INUTILIZA_CONHEC_TRANSP'
        and c.COLUMN_NAME = 'ID_INUT' 
        and c.NULLABLE    = 'N';
   exception
      when others then
         vn_qtde := 0;
   end;	
   --   
   if vn_qtde = 1 then
      -- 
	  -- Add/modify columns 
      BEGIN
         EXECUTE IMMEDIATE 'alter table CSF_OWN.INUTILIZA_CONHEC_TRANSP modify id_inut null';		 
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR ( -20101, 'Erro alterar coluna ID_INUT de INUTILIZA_CONHEC_TRANSP - '||SQLERRM );
      END;	  
      -- 
      commit;
      --	  
   end if;
   --  
end;
/

begin
   --
   begin  
     insert into csf_own.tipo_obj_integr( id
                                        , objintegr_id
                                        , cd
                                        , descr )
                                 values ( tipoobjintegr_seq.nextval
                                        , (select o.id from csf_own.obj_integr o where o.cd = '4')
                                        , '4'
                                        , 'Inutilização de Emissão Própria de Conhec. de Transporte'
                                        );       
   exception
     when others then
       update csf_own.tipo_obj_integr
          set descr = 'Inutilização de Emissão Própria de Conhec. de Transporte'
        where objintegr_id in (select o.id from csf_own.obj_integr o where o.cd = '4')
          and cd           = '4';       
   end; 
   --  
   begin  
     insert into csf_own.tipo_obj_integr( id
                                        , objintegr_id
                                        , cd
                                        , descr )
                                 values ( tipoobjintegr_seq.nextval
                                        , (select o.id from csf_own.obj_integr o where o.cd = '4')
                                        , '5'
                                        , 'Carta de Correção Emissão Própria de Conhec. de Transporte'
                                        );       
   exception
     when others then
       update csf_own.tipo_obj_integr
          set descr = 'Carta de Correção Emissão Própria de Conhec. de Transporte'
        where objintegr_id in (select o.id from csf_own.obj_integr o where o.cd = '4')
          and cd           = '5';       
   end; 
   -- 
   commit;
   --   
end;
/

--------------------------------------------------------------------------------------------------------------------------------------
Prompt FIM Redmine Redmine #73063 - Alterações para emissão de conhecimento de transporte.
--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
Prompt INI - Redmine #75898 Criação de padrão NFem a adição de Joinville-SC ao padrão
-------------------------------------------------------------------------------------------------------------------------------------------
--
--CIDADE  : Joinville - SC
--IBGE    : 4209102
--PADRAO  : NFem
--HABIL   : SIM
--WS_CANC : SIM

declare 
   --   
   -- dm_tp_amb (Tipo de Ambiente 1-Producao; 2-Homologacao)
   cursor c_dados is
      select   ( select id from csf_own.cidade where ibge_cidade = '4209102' ) id, dm_situacao,  versao,  dm_tp_amb,  dm_tp_soap,  dm_tp_serv, descr, url_wsdl, dm_upload, dm_ind_emit 
        from ( --Produção
			   select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  1 dm_tp_serv, 'Geração de NFS-e'                               descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  2 dm_tp_serv, 'Recepção e Processamento de lote de RPS'        descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  3 dm_tp_serv, 'Consulta de Situação de lote de RPS'            descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  4 dm_tp_serv, 'Consulta de NFS-e por RPS'                      descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  5 dm_tp_serv, 'Consulta de NFS-e'                              descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  6 dm_tp_serv, 'Cancelamento de NFS-e'                          descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  7 dm_tp_serv, 'Substituição de NFS-e'                          descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  8 dm_tp_serv, 'Consulta de Empresas Autorizadas a emitir NFS-e'descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  9 dm_tp_serv, 'Login'                                          descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap, 10 dm_tp_serv, 'Consulta de Lote de RPS'                        descr, 'https://nfemws.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               --Homologação
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  1 dm_tp_serv, 'Geração de NFS-e'                               descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  2 dm_tp_serv, 'Recepção e Processamento de lote de RPS'        descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  3 dm_tp_serv, 'Consulta de Situação de lote de RPS'            descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  4 dm_tp_serv, 'Consulta de NFS-e por RPS'                      descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  5 dm_tp_serv, 'Consulta de NFS-e'                              descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  6 dm_tp_serv, 'Cancelamento de NFS-e'                          descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  7 dm_tp_serv, 'Substituição de NFS-e'                          descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  8 dm_tp_serv, 'Consulta de Empresas Autorizadas a emitir NFS-e'descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  9 dm_tp_serv, 'Login'                                          descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap, 10 dm_tp_serv, 'Consulta de Lote de RPS'                        descr, 'https://nfemwshomologacao.joinville.sc.gov.br/NotaFiscal/Servicos.asmx?wsdl' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual
              );
--   
begin   
   --
      for rec_dados in c_dados loop
         exit when c_dados%notfound or (c_dados%notfound) is null;
         --
         begin  
            insert into csf_own.cidade_webserv_nfse (  id
                                                    ,  cidade_id
                                                    ,  dm_situacao
                                                    ,  versao
                                                    ,  dm_tp_amb
                                                    ,  dm_tp_soap
                                                    ,  dm_tp_serv
                                                    ,  descr
                                                    ,  url_wsdl
                                                    ,  dm_upload
                                                    ,  dm_ind_emit  )    
                                             values (  csf_own.cidadewebservnfse_seq.nextval
                                                    ,  rec_dados.id
                                                    ,  rec_dados.dm_situacao
                                                    ,  rec_dados.versao
                                                    ,  rec_dados.dm_tp_amb
                                                    ,  rec_dados.dm_tp_soap
                                                    ,  rec_dados.dm_tp_serv
                                                    ,  rec_dados.descr
                                                    ,  rec_dados.url_wsdl
                                                    ,  rec_dados.dm_upload
                                                    ,  rec_dados.dm_ind_emit  ); 
            --
            commit;        
            --
         exception  
            when dup_val_on_index then 
               begin 
                  update csf_own.cidade_webserv_nfse 
                     set versao      = rec_dados.versao
                       , dm_tp_soap  = rec_dados.dm_tp_soap
                       , descr       = rec_dados.descr
                       , url_wsdl    = rec_dados.url_wsdl
                       , dm_upload   = rec_dados.dm_upload
                   where cidade_id   = rec_dados.id 
                     and dm_tp_amb   = rec_dados.dm_tp_amb 
                     and dm_tp_serv  = rec_dados.dm_tp_serv 
                     and dm_ind_emit = rec_dados.dm_ind_emit; 
                  --
                  commit; 
                  --
               exception when others then 
                  raise_application_error(-20101, 'Erro no script Redmine #75898 Atualização URL ambiente de homologação e Produção Joinville - SC' || sqlerrm);
               end; 
               --
         end;
         -- 
      --
      end loop;
   --
   commit;
   --
exception
   when others then
      raise_application_error(-20102, 'Erro no script Redmine #75898 Atualização URL ambiente de homologação e Produção Joinville - SC' || sqlerrm);
end;
/

declare
vn_count integer;
--
begin
  ---
  vn_count:=0;
  ---
  begin
    select count(1) into vn_count
    from  all_constraints 
    where owner = 'CSF_OWN'
      and constraint_name = 'CIDADENFSE_DMPADRAO_CK';
  exception
    when others then
      vn_count:=0;
  end;
  ---
  if vn_count = 1 then
     begin  
		execute immediate 'alter table CSF_OWN.CIDADE_NFSE drop constraint CIDADENFSE_DMPADRAO_CK';
		execute immediate 'alter table CSF_OWN.CIDADE_NFSE add constraint CIDADENFSE_DMPADRAO_CK check (dm_padrao in (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45))';
	 exception 
		when others then
			null;
	 end;
  elsif  vn_count = 0 then    
     begin
		execute immediate 'alter table CSF_OWN.CIDADE_NFSE add constraint CIDADENFSE_DMPADRAO_CK check (dm_padrao in (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45))';
	 exception 
		when others then
			null;
	 end;
  end if;
  --
  commit;  
  --
  begin
	  insert into CSF_OWN.DOMINIO (  dominio
								  ,  vl
								  ,  descr
								  ,  id  )    
						   values (  'CIDADE_NFSE.DM_PADRAO'
								  ,  '45'
								  ,  'NFem'
								  ,  CSF_OWN.DOMINIO_SEQ.NEXTVAL  ); 
	  --
	  commit;        
	  --
  exception  
      when dup_val_on_index then 
          begin 
              update CSF_OWN.DOMINIO 
                 set vl      = '45'
               where dominio = 'CIDADE_NFSE.DM_PADRAO'
                 and descr   = 'NFem'; 
	  	      --
              commit; 
              --
           exception when others then 
                raise_application_error(-20101, 'Erro no script Redmine #75898 Adicionar Padrão para emissão de NFS-e (NFem)' || sqlerrm);
             --
          end;
  end; 
end;			
/
 
declare
--
vn_dm_tp_amb1  number  := 0;
vn_dm_tp_amb2  number  := 0;
vv_ibge_cidade csf_own.cidade.ibge_cidade%type;
vv_padrao      csf_own.dominio.descr%type;    
vv_habil       csf_own.dominio.descr%type;
vv_ws_canc     csf_own.dominio.descr%type;

--
Begin
	-- Popula variáveis
	vv_ibge_cidade := '4209102';
	vv_padrao      := 'NFem';     
	vv_habil       := 'SIM';
	vv_ws_canc     := 'SIM';

    begin
      --
      SELECT count(*)
        into vn_dm_tp_amb1
        from csf_own.empresa
       where dm_tp_amb = 1
       group by dm_tp_amb;
      exception when others then
        vn_dm_tp_amb1 := 0; 
      --
    end;
   --
    Begin
      --
      SELECT count(*)
        into vn_dm_tp_amb2
        from csf_own.empresa
       where dm_tp_amb = 2
       group by dm_tp_amb;
      --
	  exception when others then 
        vn_dm_tp_amb2 := 0;
     --
    end;
--
	if vn_dm_tp_amb2 > vn_dm_tp_amb1 then
	  --
	  begin
	    --  
	    update csf_own.cidade_webserv_nfse
		   set url_wsdl = 'DESATIVADO AMBIENTE DE PRODUCAO'
	     where cidade_id in (select id
							   from csf_own.cidade
							  where ibge_cidade in (vv_ibge_cidade))
		   and dm_tp_amb = 1;
	  exception 
		 when others then
		   null;
	  end;
	  --  
	  commit;
	  --
	end if;
--
	begin
		--
		update csf_own.cidade_nfse set dm_padrao    = (select distinct vl from csf_own.dominio where upper(dominio) = upper('cidade_nfse.dm_padrao') and upper(descr) = upper(vv_padrao))
								       , dm_habil   = (select distinct vl from csf_own.dominio where upper(dominio) = upper('cidade_nfse.dm_habil') and upper(descr) = upper(vv_habil))
								       , dm_ws_canc = (select distinct vl from csf_own.dominio where upper(dominio) = upper('cidade_nfse.dm_ws_canc') and upper(descr) = upper(vv_ws_canc))
         where cidade_id = (select distinct id from csf_own.cidade where ibge_cidade in (vv_ibge_cidade));
		exception when others then
			raise_application_error(-20103, 'Erro no script Redmine #75898 Atualização do Padrão Joinville - SC' || sqlerrm);
    end;
	--
	commit;
	--
--
end;
--
/  

-------------------------------------------------------------------------------------------------------------------------------------------
Prompt FIM - Redmine #75898 Criação de padrão NFem a adição de Joinville-SC ao padrão
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
Prompt INI - Redmine #75749 Sincronização dos scripts Padrão Tinus Goiana - PE
-------------------------------------------------------------------------------------------------------------------------------------------
--
--CIDADE  : Goiana - PE
--IBGE    : 2606200
--PADRAO  : Tinus
--HABIL   : SIM
--WS_CANC : SIM

declare 
   --   
   -- dm_tp_amb (Tipo de Ambiente 1-Producao; 2-Homologacao)
   cursor c_dados is
      select   ( select id from csf_own.cidade where ibge_cidade = '2606200' ) id, dm_situacao,  versao,  dm_tp_amb,  dm_tp_soap,  dm_tp_serv, descr, url_wsdl, dm_upload, dm_ind_emit 
        from ( --Produção
			   select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  1 dm_tp_serv, 'Geração de NFS-e'                               descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  2 dm_tp_serv, 'Recepção e Processamento de lote de RPS'        descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  3 dm_tp_serv, 'Consulta de Situação de lote de RPS'            descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.ConsultarSituacaoLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  4 dm_tp_serv, 'Consulta de NFS-e por RPS'                      descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.ConsultarNfsePorRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  5 dm_tp_serv, 'Consulta de NFS-e'                              descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.ConsultarNfse.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  6 dm_tp_serv, 'Cancelamento de NFS-e'                          descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.CancelarNfse.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  7 dm_tp_serv, 'Substituição de NFS-e'                          descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  8 dm_tp_serv, 'Consulta de Empresas Autorizadas a emitir NFS-e'descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap,  9 dm_tp_serv, 'Login'                                          descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 1 dm_tp_amb, 2 dm_tp_soap, 10 dm_tp_serv, 'Consulta de Lote de RPS'                        descr, 'http://www.tinus.com.br/csp/goiana/WSNFSE.ConsultarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               --Homologação
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  1 dm_tp_serv, 'Geração de NFS-e'                               descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  2 dm_tp_serv, 'Recepção e Processamento de lote de RPS'        descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  3 dm_tp_serv, 'Consulta de Situação de lote de RPS'            descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.ConsultarSituacaoLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  4 dm_tp_serv, 'Consulta de NFS-e por RPS'                      descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.ConsultarNfsePorRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  5 dm_tp_serv, 'Consulta de NFS-e'                              descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.ConsultarNfse.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  6 dm_tp_serv, 'Cancelamento de NFS-e'                          descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.CancelarNfse.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  7 dm_tp_serv, 'Substituição de NFS-e'                          descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  8 dm_tp_serv, 'Consulta de Empresas Autorizadas a emitir NFS-e'descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap,  9 dm_tp_serv, 'Login'                                          descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.RecepcionarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual union
               select 1 dm_situacao, '1' versao, 2 dm_tp_amb, 2 dm_tp_soap, 10 dm_tp_serv, 'Consulta de Lote de RPS'                        descr, 'http://www2.tinus.com.br/csp/testegoi/WSNFSE.ConsultarLoteRps.CLS?WSDL=1' url_wsdl, 0 dm_upload,  0 dm_ind_emit from dual
              );
--   
begin   
   --
      for rec_dados in c_dados loop
         exit when c_dados%notfound or (c_dados%notfound) is null;
         --
         begin  
            insert into csf_own.cidade_webserv_nfse (  id
                                                    ,  cidade_id
                                                    ,  dm_situacao
                                                    ,  versao
                                                    ,  dm_tp_amb
                                                    ,  dm_tp_soap
                                                    ,  dm_tp_serv
                                                    ,  descr
                                                    ,  url_wsdl
                                                    ,  dm_upload
                                                    ,  dm_ind_emit  )    
                                             values (  csf_own.cidadewebservnfse_seq.nextval
                                                    ,  rec_dados.id
                                                    ,  rec_dados.dm_situacao
                                                    ,  rec_dados.versao
                                                    ,  rec_dados.dm_tp_amb
                                                    ,  rec_dados.dm_tp_soap
                                                    ,  rec_dados.dm_tp_serv
                                                    ,  rec_dados.descr
                                                    ,  rec_dados.url_wsdl
                                                    ,  rec_dados.dm_upload
                                                    ,  rec_dados.dm_ind_emit  ); 
            --
            commit;        
            --
         exception  
            when dup_val_on_index then 
               begin 
                  update csf_own.cidade_webserv_nfse 
                     set versao      = rec_dados.versao
                       , dm_tp_soap  = rec_dados.dm_tp_soap
                       , descr       = rec_dados.descr
                       , url_wsdl    = rec_dados.url_wsdl
                       , dm_upload   = rec_dados.dm_upload
                   where cidade_id   = rec_dados.id 
                     and dm_tp_amb   = rec_dados.dm_tp_amb 
                     and dm_tp_serv  = rec_dados.dm_tp_serv 
                     and dm_ind_emit = rec_dados.dm_ind_emit; 
                  --
                  commit; 
                  --
               exception when others then 
                  raise_application_error(-20101, 'Erro no script Redmine #75749 Atualização URL ambiente de homologação e Produção Goiana - PE' || sqlerrm);
               end; 
               --
         end;
         -- 
      --
      end loop;
   --
   commit;
   --
exception
   when others then
      raise_application_error(-20102, 'Erro no script Redmine #75749 Atualização URL ambiente de homologação e Produção Goiana - PE' || sqlerrm);
end;
/

declare
--
vn_dm_tp_amb1  number  := 0;
vn_dm_tp_amb2  number  := 0;
vv_ibge_cidade csf_own.cidade.ibge_cidade%type;
vv_padrao      csf_own.dominio.descr%type;    
vv_habil       csf_own.dominio.descr%type;
vv_ws_canc     csf_own.dominio.descr%type;

--
Begin
	-- Popula variáveis
	vv_ibge_cidade := '2606200';
	vv_padrao      := 'Tinus';     
	vv_habil       := 'SIM';
	vv_ws_canc     := 'SIM';

    begin
      --
      SELECT count(*)
        into vn_dm_tp_amb1
        from csf_own.empresa
       where dm_tp_amb = 1
       group by dm_tp_amb;
      exception when others then
        vn_dm_tp_amb1 := 0; 
      --
    end;
   --
    Begin
      --
      SELECT count(*)
        into vn_dm_tp_amb2
        from csf_own.empresa
       where dm_tp_amb = 2
       group by dm_tp_amb;
      --
	  exception when others then 
        vn_dm_tp_amb2 := 0;
     --
    end;
--
	if vn_dm_tp_amb2 > vn_dm_tp_amb1 then
	  --
	  begin
	    --  
	    update csf_own.cidade_webserv_nfse
		   set url_wsdl = 'DESATIVADO AMBIENTE DE PRODUCAO'
	     where cidade_id in (select id
							   from csf_own.cidade
							  where ibge_cidade in (vv_ibge_cidade))
		   and dm_tp_amb = 1;
	  exception 
		 when others then
		   null;
	  end;
	  --  
	  commit;
	  --
	end if;
--
	begin
		--
		update csf_own.cidade_nfse set dm_padrao    = (select distinct vl from csf_own.dominio where upper(dominio) = upper('cidade_nfse.dm_padrao') and upper(descr) = upper(vv_padrao))
								       , dm_habil   = (select distinct vl from csf_own.dominio where upper(dominio) = upper('cidade_nfse.dm_habil') and upper(descr) = upper(vv_habil))
								       , dm_ws_canc = (select distinct vl from csf_own.dominio where upper(dominio) = upper('cidade_nfse.dm_ws_canc') and upper(descr) = upper(vv_ws_canc))
         where cidade_id = (select distinct id from csf_own.cidade where ibge_cidade in (vv_ibge_cidade));
		exception when others then
			raise_application_error(-20103, 'Erro no script Redmine #75749 Atualização do Padrão Goiana - PE' || sqlerrm);
    end;
	--
	commit;
	--
--
end;
--
/  

-------------------------------------------------------------------------------------------------------------------------------------------
Prompt FIM - Redmine #75749 Sincronização dos scripts Padrão Tinus Goiana - PE
-------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------
Prompt INI - Redmine #75876  - Cancelamento rejeitado fica sendo reenviado
-------------------------------------------------------------------------------------------------------------------------------
declare
   vn_existe number := null;
begin 
   select count(*)
     into vn_existe
     from sys.all_tab_columns ac 
    where ac.OWNER       = 'CSF_OWN'
      and ac.TABLE_NAME  = 'CONHEC_TRANSP_CANC'
      and ac.COLUMN_NAME = 'DM_CANC_SERVICO';
   --
   if nvl(vn_existe,0) = 0 then
      --
      execute immediate 'alter table CSF_OWN.CONHEC_TRANSP_CANC add DM_CANC_SERVICO NUMBER(1) default 0';
      execute immediate 'comment on column CSF_OWN.CONHEC_TRANSP_CANC.DM_CANC_SERVICO is ''Campo que indica se ja houve a tentativa de cancelamento pela mensageria''';
      execute immediate 'alter table CSF_OWN.CONHEC_TRANSP_CANC add constraint CTCANC_CANCSERVICO check (DM_CANC_SERVICO IN (0, 1))';
      execute immediate 'create index CTCANC_CONHECTRANSP_ID01 on CSF_OWN.CONHEC_TRANSP_CANC (CONHECTRANSP_ID,DM_CANC_SERVICO)';
      --
   elsif nvl(vn_existe,0) > 0 then
      --
      execute immediate 'comment on column CSF_OWN.CONHEC_TRANSP_CANC.DM_CANC_SERVICO is ''Campo que indica se ja houve a tentativa de cancelamento pela mensageria''';      
      --
   end if;
   -- 
exception
   when others then
      raise_application_error(-20001, 'Erro no script 75897. Campo DM_ST_PROC. Erro: ' || sqlerrm);      
end;
/

begin 
   execute immediate 'insert into csf_own.dominio (dominio, vl, descr, id) values (''CONHEC_TRANSP_CANC.DM_CANC_SERVICO'', ''0'' , ''Nao'', csf_own.dominio_seq.nextval )';
   commit;
exception
   when dup_val_on_index then
      null;      
   when others then
      raise_application_error(-20001, 'Erro no script 75897. Domínio CONHEC_TRANSP_CANC.DM_CANC_SERVICO e Valor "0". Erro: ' || sqlerrm);      
end;
/  

begin 
   execute immediate 'insert into csf_own.dominio (dominio, vl, descr, id) values (''CONHEC_TRANSP_CANC.DM_CANC_SERVICO'', ''1'' , ''Sim'', csf_own.dominio_seq.nextval )';
   commit;
exception
   when dup_val_on_index then
      null;      
   when others then
      raise_application_error(-20001, 'Erro no script 75897. Domínio CONHEC_TRANSP_CANC.DM_CANC_SERVICO e Valor "1". Erro: ' || sqlerrm);      
end;
/  

-------------------------------------------------------------------------------------------------------------------------------
Prompt FIM - Redmine #75876  - Cancelamento rejeitado fica sendo reenviado 
-------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
Prompt Inicio Redmine #75742: Customização ACG.
---------------------------------------------------------------------------------------------------------


declare
vn_count number;
begin
  ---
  vn_count:=0;
  --
  -- valida se ja existe a coluna na tabela PARAM_GERA_INF_PROV_DOC_FISC, senao existir, cria.
  BEGIN
    SELECT count(1) 
        into vn_count
      FROM ALL_TAB_COLUMNS
     WHERE UPPER(OWNER)       = UPPER('CSF_OWN')
       AND UPPER(TABLE_NAME)  = UPPER('PARAM_GERA_INF_PROV_DOC_FISC')
       AND UPPER(COLUMN_NAME) = UPPER('ORIG');
    exception
    when others then
      vn_count:=0;
  end;
  ---
  if  vn_count = 0 then
   begin 
      EXECUTE IMMEDIATE 'ALTER TABLE CSF_OWN.PARAM_GERA_INF_PROV_DOC_FISC ADD ORIG NUMBER(1)';
      EXECUTE IMMEDIATE 'comment on column CSF_OWN.PARAM_GERA_INF_PROV_DOC_FISC.ORIG  is ''Origem da mercadoria''';
    exception
    when others then
      null;
  end;
  --
 end if;
 --
 end;
/

declare
vn_count number;
begin
  ---
  vn_count:=0;
  ---
  begin
    select count(1) into vn_count
    from all_constraints a
    where a.owner         ='CSF_OWN'
    and a.table_name      ='PARAM_GERA_INF_PROV_DOC_FISC'
    and a.constraint_name ='INFPROVDOCFISC_ORIG_CK';
  exception
    when others then
      vn_count:=0;
  end;
  ---
  if  vn_count = 0 then
   begin
    execute immediate 'alter table CSF_OWN.PARAM_GERA_INF_PROV_DOC_FISC add constraint INFPROVDOCFISC_ORIG_CK check (ORIG in (0, 1, 2, 3, 4, 5, 6, 7, 8))';
    exception
    when others then
      null;
   end;
  end if;
  ---
  commit;
end;
/

 

declare
vn_count number;
begin
  ---
  vn_count:=0;
  ---
BEGIN
  --
  -- valida se ja existe a coluna na tabela PARAM_GERA_INF_PROV_DOC_FISC, senao existir, cria.
    SELECT  count(1) 
        into vn_count
      FROM ALL_TAB_COLUMNS
     WHERE UPPER(OWNER)       = UPPER('CSF_OWN')
       AND UPPER(TABLE_NAME)  = UPPER('PARAM_GERA_REG_SUB_APUR_ICMS')
       AND UPPER(COLUMN_NAME) = UPPER('ORIG');
    exception
    when others then
      vn_count:=0;
  end;
  ---
  if  vn_count = 0 then
   begin 
      EXECUTE IMMEDIATE 'ALTER TABLE CSF_OWN.PARAM_GERA_REG_SUB_APUR_ICMS ADD ORIG NUMBER(1)';
      EXECUTE IMMEDIATE 'comment on column CSF_OWN.PARAM_GERA_REG_SUB_APUR_ICMS.ORIG  is ''Origem da mercadoria''';
    exception
    when others then
      null;
  end;
  --
  end if;
  --
END;
/
 
 

declare
vn_count number;
begin
  ---
  vn_count:=0;
  ---
  begin
    select count(1) into vn_count
    from all_constraints a
    where a.owner         ='CSF_OWN'
    and a.table_name      ='PARAM_GERA_REG_SUB_APUR_ICMS'
    and a.constraint_name ='REGSUBAPURICMS_ORIG_CK';
  exception
    when others then
      vn_count:=0;
  end;
  ---
  if  vn_count = 0 then
   begin
    execute immediate 'alter table CSF_OWN.PARAM_GERA_REG_SUB_APUR_ICMS add constraint REGSUBAPURICMS_ORIG_CK check (ORIG in (0, 1, 2, 3, 4, 5, 6, 7, 8))';
    exception
    when others then
      null;
   end;
  end if;
  ---
  commit;
end;
/ 
 

--retirar UK da tabela  
declare
  v_existe  number := 0 ;
begin
  --
  begin
    -- verifica se existe uk
     select 1
       into v_existe
       from all_constraints a
      where upper(a.OWNER) = upper('CSF_OWN')
        and upper(a.TABLE_NAME) = upper('PARAM_GERA_REG_SUB_APUR_ICMS')
        and upper(a.CONSTRAINT_NAME) = upper('PARAMGERRSAI_CFOPCSTPER_UK');
    --
  exception
    when others then
      v_existe := 0 ;
  end ;
  --
  -- se existir dropa ela
  if v_existe > 0 then
    --
    begin
      execute immediate 'ALTER TABLE CSF_OWN.PARAM_GERA_REG_SUB_APUR_ICMS DROP CONSTRAINT PARAMGERRSAI_CFOPCSTPER_UK';
    exception
     when others then
       raise_application_error(-20101, 'Erro ao excluir constraint no script 75742 Customização ACG - ' || sqlerrm);
    end ;
    --
  end if;
  --
     -- cria novamente com o campo ORI
    begin
      execute immediate 'alter table CSF_OWN.PARAM_GERA_REG_SUB_APUR_ICMS
  add constraint PARAMGERRSAI_CFOPCSTPER_UK unique (EMPRESA_ID, CFOP_ID, CODST_ID, ALIQ_ICMS, ORIG)
  using index tablespace CSF_DATA';
    exception
     when others then
       raise_application_error(-20101, 'Erro ao excluir constraint no script 75742 Customização ACG - ' || sqlerrm);
    end ;

end;
/
  
  
  
  

 
  
--retirar UK da tabela  
declare
  v_existe  number := 0 ;
begin
  --
  begin
    -- verifica se existe uk
     select 1
       into v_existe
       from all_constraints a
      where upper(a.OWNER) = upper('CSF_OWN')
        and upper(a.TABLE_NAME) = upper('PARAM_GERA_INF_PROV_DOC_FISC')
        and upper(a.CONSTRAINT_NAME) = upper('PARAMGERAIPDF_CFOPCSTPER_UK');
    --
  exception
    when others then
      v_existe := 0 ;
  end ;
  --
  -- se existir dropa ela
  if v_existe > 0 then
    --
    begin
      execute immediate 'ALTER TABLE CSF_OWN.PARAM_GERA_INF_PROV_DOC_FISC DROP CONSTRAINT PARAMGERAIPDF_CFOPCSTPER_UK';
    exception
     when others then
       raise_application_error(-20101, 'Erro ao excluir constraint no script 75742 Customização ACG - ' || sqlerrm);
    end ;
    --
  end if;
    -- cria novamente com o campo ORI
    begin
      execute immediate 'alter table CSF_OWN.PARAM_GERA_INF_PROV_DOC_FISC
  add constraint PARAMGERAIPDF_CFOPCSTPER_UK unique (EMPRESA_ID, CFOP_ID, CODST_ID, ALIQ_ICMS, ORIG)
  using index tablespace CSF_DATA';
    exception
     when others then
       raise_application_error(-20101, 'Erro ao excluir constraint no script 75742 Customização ACG - ' || sqlerrm);
    end ;
  --
end;
/

---------------------------------------------------------------------------------------------------------
Prompt Inicio Redmine #75742: Customização ACG.
---------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
Prompt FIM Patch 2.9.6.2 - Alteracoes no CSF_OWN
------------------------------------------------------------------------------------------
