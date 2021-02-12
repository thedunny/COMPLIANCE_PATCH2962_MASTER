CREATE OR REPLACE TRIGGER CSF_OWN.T_A_U_ITEM_AGEND_INTEGR_01
  AFTER UPDATE OF DM_SITUACAO ON CSF_OWN.ITEM_AGEND_INTEGR
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW when (nvl (old.DM_SITUACAO, 0) != nvl (new.DM_SITUACAO, 0))
declare
  --
  -- Em 08/02/2021  - Wendel Albino
  -- Redmine #75700 - Integração Nova America
  --                - Empresa NOVA AMERICA - Foram incluidos (vn_hash <> 'c4ca4238a0b923820dcc509a6f75849b' 
  --                  or vn_descr <> 'DEFAULT MULT-ORGANIZACAO') na validacao para a trigger nao ser acionada.
  -- 
  -- Em 04/01/2021  - Renan Alves
  -- Redmine #74022 - Agendamento de Integração sem buscar os dados do EBS para nossa view
  -- Foi incluído uma verificação na hash do multorg utilizado no agendamento integração, para que seja
  -- verificado se o agendamento é do cliente Venancio, e sendo do mesmo, a trigger não deve funcionar, pois,
  -- eles utilizam outro job para os agendamentos de integração.
  -- Patch_2.9.6.1 / Release_2.9.6
  --
  -- Em 18/12/2020 - Renan Alves
  -- Redmine #74370 - Falha no agendamento de integração - status "agendado" (ACECO)
  -- Na criação do JOB foi alterado o sysdate incluindo sysdate + 15 segundos (sysdate+((1/24)/60/4)),
  -- para a execução de todos os itens do agendamento de integração
  -- Patch_2.9.5.3 / Release_2.9.6
  --
  -- Em 19/10/2020 - Renan Alves
  -- Redmine #72545 - Integração de dados com erro
  -- Foi incluido um select na tabela ALL_SCHEDULER_JOBS para verificar se o job já existe,
  -- e caso ele já exista, não é criado o job novamente.
  -- Patch_2.9.5.2 / Release_2.9.6
  --
  -- Redmine #71806 - Integração simultânea para multorg 1 deu erro ORA 06519
  -- Incluir commit nos updates da tabela  agend_integr
  -- Liberado para release 295 e patch 294-3.
  --
  -- Redmine #69166 - Criação de trigger no lugar do job AGEND_INTEGR
  -- Criação da trigger para gerar job scheduler para rotina pk_agend_integr.pkb_inicia_agend_integr
  -- Liberado para release 295 e patch 294-3.
  --
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
  vn_fase           number;
  vn_dm_sit_new     number(1);
  vn_emp_id         number;
  vn_multorg_id     number;
  vn_count          number;
  vv_job_name       varchar2(40);
  vn_id             number;
  vv_sql            varchar2(4000);
  vn_id_ag          agend_integr.id%type;
  vn_obj_id         item_agend_integr.objintegr_id%type;
  vn_hash           mult_org.hash%type := null;
  vn_descr          mult_org.descr%type := null;
  --
  vn_exist          number := 0;
  vn_loggenerico_id log_generico.id%type;
  gv_mensagem       log_generico.mensagem%type;
  gv_resumo         log_generico.resumo%type;
  gv_obj_referencia log_generico.obj_referencia%type default 'ITEM_AGEND_INTEGR';
  informacao        constant number := 35;
  VD_DT_AGEND       AGEND_INTEGR.DT_AGEND%TYPE;
  --
  cursor c_ag(en_multorg_id pessoa.multorg_id%type,
              en_emp_id     agend_integr.empresa_id%type,
              en_obj_id     item_agend_integr.objintegr_id%type) is
    select a.id
      from agend_integr a,
           item_agend_integr i,
           empresa e,
           pessoa p
     where a.id          = i.agendintegr_id
       and a.dm_situacao = 6 -- Aguardando Execução Anterior --in (1,2) -- 1-Agendado, 2-Integrando
       and i.dm_integr   = 1 -- 0-Não, 1-Sim
       and a.empresa_id  = e.id
       and e.pessoa_id   = p.id
       and p.multorg_id  = en_multorg_id
       and a.empresa_id  <> en_emp_id;
  --
begin
  --
  vn_fase := 1;
  --
  vn_dm_sit_new := :new.dm_situacao;
  vn_id         := :new.agendintegr_id;
  vv_job_name   := null;
  vn_obj_id     := :new.objintegr_id;
  --
  vn_fase := 2;
  --
  select empresa_id
    into vn_emp_id
    from agend_integr
   where id = vn_id;
  --
  vn_fase := 3;
  --
  vn_multorg_id := pk_csf.fkg_multorg_id_empresa(vn_emp_id);
  --
  vn_fase := 4;
  --
  -- Recupera hash e descrição do multorg
  -- utilizado no agendamento de integração
  begin
    select m.hash,
           upper(m.descr)
      into vn_hash,
           vn_descr
      from mult_org m
     where m.id = vn_multorg_id;
  exception
    when others then
      vn_hash  := '0';
      vn_descr := '0';
  end;
  --
  vn_fase := 5;
  --
  -- Verifica se a hash ou a descrição pertence a Venancio ou Nova America,
  -- caso pertençam aoS mesmoS, a trigger não deve ser acionada
  if (vn_hash <> 'c0c7c76d30bd3dcaefc96f40275bdc0a' or vn_descr <> 'VENANCIO') 
    or (vn_hash <> 'c4ca4238a0b923820dcc509a6f75849b' or vn_descr <> 'DEFAULT MULT-ORGANIZACAO') then
    --
    begin
     select a.dt_agend
       into vd_dt_agend
       from agend_integr a
      where a.id = vn_id;
     exception
      when others then
        vd_dt_agend := sysdate+((1/24)/60/4);
    end;
    --
    if vn_dm_sit_new = 1 then -- 1-Agendado
      --
      vn_fase := 6;
      --
      vn_count := 0;
      --
      begin
        select count(1)
          into vn_count
          from agend_integr a,
               item_agend_integr i,
               empresa e,
               pessoa p
         where a.id           = i.agendintegr_id
           and a.dm_situacao  in (/*1,*/ 2) -- 1-Agendado, 2-Integrando
           and i.dm_integr    = 1 -- 0-Não, 1-Sim
           and a.empresa_id   = e.id
           and e.pessoa_id    = p.id
           and i.objintegr_id = vn_obj_id
           and p.multorg_id   = vn_multorg_id
           and a.empresa_id   <> vn_emp_id;
      exception
        when others then
          vn_count := 0;
      end;
      --
      vn_fase := 7;
      --
      if vn_count > 0 then
        --
        vn_fase := 8;
        --
        update agend_integr
           set dm_situacao = 6 -- Aguardando Execução Anterior
         where id          = :new.id;
        --
        commit;
        --
      elsif vn_count = 0 then
        --
        vn_fase := 9;
        --
        vv_job_name := 'JOB_' || vn_id;
        --
        -- Verifica se o job já existe
        begin
          select count(0)
            into vn_exist
            from all_scheduler_jobs a
           where a.job_name = vv_job_name;
        exception
          when others then
            vn_exist := 0;
        end;
        --
        if vn_exist = 0 then
          --
          vn_fase := 10;
          --
          begin
            --
            vv_sql := vv_sql || 'BEGIN ';
            vv_sql := vv_sql || 'DBMS_SCHEDULER.CREATE_JOB ( ';
            vv_sql := vv_sql || 'job_name => ' || '''' || vv_job_name || '''';
            vv_sql := vv_sql || ', job_type => ' || '''' || 'PLSQL_BLOCK' || '''';
            vv_sql := vv_sql || ', job_action => ' || '''' || 'begin pk_agend_integr.pkb_inic_agendintegr_multorg(' || vn_multorg_id || ');end;' || '''';
            --vv_sql := vv_sql || ', start_date => sysdate+((1/24)/60/4) ';
            vv_sql := vv_sql || ', start_date => TO_DATE('||''''||to_char(vd_dt_agend,'DD/MM/RRRR HH24:MI:SS')||''''||','||'''DD/MM/RRRR HH24:MI:SS'')';
            vv_sql := vv_sql || ', auto_drop => true ';
            vv_sql := vv_sql || ', enabled =>  TRUE); ';
            vv_sql := vv_sql || 'END;';
            --
            begin
              execute immediate vv_sql;
            exception
              when others then
                raise_application_error(-20101, 'Problemas ao criar job em T_A_U_ITEM_AGEND_INTEGR_01. (' || vn_fase || '): ' || sqlerrm);
            end;
            --
          end;
          --
        else
          --
          vn_fase := 11;
          --
          gv_mensagem := 'Já existe um processo de agendamento ( ID: ' || vn_id || ') em andamento. (' || vn_fase || ').';
          gv_resumo   := 'Já existe um processo de agendamento ( ID: ' || vn_id || ') em andamento. (' || vn_fase || ').';
          --
          pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                           ev_mensagem       => gv_mensagem,
                                           ev_resumo         => gv_resumo,
                                           en_tipo_log       => informacao,
                                           en_referencia_id  => vn_id,
                                           ev_obj_referencia => gv_obj_referencia,
                                           en_empresa_id     => vn_emp_id,
                                           en_dm_impressa    => 1);
          --
        end if;
        --
      end if;
      --
    elsif vn_dm_sit_new in (3, 4) then -- 3-Finalizado, 4-Erro
      --
      vn_fase := 12;
      --
      vn_id_ag := 0;
      --
      for rec_ag in c_ag(vn_multorg_id, vn_emp_id, vn_obj_id) loop
        exit when c_ag%notfound or(c_ag%notfound) is null;
        --
        vn_fase := 13;
        --
        vn_id_ag := rec_ag.id;
        --
        update agend_integr
           set dm_situacao = 1 -- 1-Agendado
         where id          = vn_id_ag;
        --
        commit;
        --
        vn_fase := 14;
        --
        vv_job_name := 'JOB_' || vn_id_ag;
        --
        -- Verifica se o job já encontra-se criado
        begin
          select count(0)
            into vn_exist
            from all_scheduler_jobs a
           where a.job_name = vv_job_name;
        exception
          when others then
            vn_exist := 0;
        end;
        --
        if vn_exist = 0 then
          --
          vn_fase := 15;
          --
          begin
            --
            vv_sql := vv_sql || 'BEGIN ';
            vv_sql := vv_sql || 'DBMS_SCHEDULER.CREATE_JOB ( ';
            vv_sql := vv_sql || 'job_name => ' || '''' || vv_job_name || '''';
            vv_sql := vv_sql || ', job_type => ' || '''' || 'PLSQL_BLOCK' || '''';
            vv_sql := vv_sql || ', job_action => ' || '''' || 'begin pk_agend_integr.pkb_inic_agendintegr_multorg(' || vn_multorg_id || ');end;' || '''';
            vv_sql := vv_sql || ', start_date => TO_DATE('||''''||to_char(vd_dt_agend,'DD/MM/RRRR HH24:MI:SS')||''''||','||'''DD/MM/RRRR HH24:MI:SS'')';
            vv_sql := vv_sql || ', auto_drop => true ';
            vv_sql := vv_sql || ', enabled =>  TRUE); ';
            vv_sql := vv_sql || 'END;';
            --
            begin
              execute immediate vv_sql;
            exception
              when others then
                raise_application_error(-20102, 'Problemas ao criar job em T_A_U_ITEM_AGEND_INTEGR_01. (' || vn_fase || '): ' || sqlerrm);
            end;
            --
          end;
          --
        else
          --
          vn_fase := 16;
          --
          gv_mensagem := 'Já existe um processo de agendamento ( ID: ' || vn_id || ') em andamento. (' || vn_fase || ').';
          gv_resumo   := 'Já existe um processo de agendamento ( ID: ' || vn_id || ') em andamento. (' || vn_fase || ').';
          --
          pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                           ev_mensagem       => gv_mensagem,
                                           ev_resumo         => gv_resumo,
                                           en_tipo_log       => informacao,
                                           en_referencia_id  => vn_id,
                                           ev_obj_referencia => gv_obj_referencia,
                                           en_empresa_id     => vn_emp_id,
                                           en_dm_impressa    => 1);
          --
        end if;
        --
      end loop; -- c_ag
      --
    end if; -- vn_dm_sit_new
    --
  end if; -- hash e descr
  --
exception
  when others then
    raise_application_error(-20103, 'Erro Geral na execução da Trigger - T_A_U_AGEND_INTEGR_01 - vn_fase (' || vn_fase || '). Erro: ' || sqlerrm);
end T_A_U_ITEM_AGEND_INTEGR_01;
/
