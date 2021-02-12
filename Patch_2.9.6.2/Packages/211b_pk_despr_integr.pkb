create or replace package body csf_own.pk_despr_integr is

------------------------------------------------------------------------------------------
--| Corpo da package de Desprocessar Integração de Dados Fiscais
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
-- Procedimento armazena o log de desprocessamento da informação
------------------------------------------------------------------------------------------
procedure pkb_reg_log_despr_integr ( en_empresa_id in empresa.id%Type
                                   , en_usuario_id in neo_usuario.id%type
                                   , ed_dt_ini     in date
                                   , ed_dt_fin     in date
                                   , ev_texto      in varchar2
                                   )
is
   --
   vn_fase            number := 0;
   vn_loggenerico_id  log_generico.id%type;
   vv_usuario         varchar2(200);
   vv_empresa         varchar2(150);
   --
begin
   --
   vn_fase := 1;
   --
   begin
      select (login || '-' || nome)
        into vv_usuario
        from neo_usuario
       where id = en_usuario_id;
   exception
      when others then
         vv_usuario := null;
   end;
   --
   vn_fase := 2;
   --
   vv_resumo := 'Usuário: ' || vv_usuario
                || ' desprocessou as informações de ' || trim(ev_texto) -- terminar com ponto final '.' nessa variável
                || ' Período de ' || to_char(ed_dt_ini, 'dd/mm/rrrr') || ' até ' || to_char(ed_dt_fin, 'dd/mm/rrrr')||', '; -- seguem mais informações abaixo
   --
   vn_fase := 3;
   --
   if nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 4;
      --
      begin
         select ( p.cod_part || '-' || p.nome )
           into vv_empresa
           from empresa  e
              , usuario_empresa ue
              , pessoa   p
          where e.id = en_empresa_id
            and p.id = e.pessoa_id
            and ue.empresa_id = e.id
            and ue.usuario_id = en_usuario_id;
      exception
         when others then
            vv_empresa := null;
      end;
      --
      vn_fase   := 5;
      vv_resumo := vv_resumo || ' da empresa ' || vv_empresa || '.';
      --
   else
      vn_fase := 6;
      vv_resumo := vv_resumo || ' de todas as empresas usuárias.';
   end if;
   --
   vn_fase := 7;
   pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                    , ev_mensagem       => 'Desprocessar Integração'
                                    , ev_resumo         => vv_resumo
                                    , en_tipo_log       => informacao
                                    , en_referencia_id  => 1
                                    , ev_obj_referencia => 'DESPR_INTEGR'
                                    , en_empresa_id     => gn_empresa_id
                                    , en_dm_impressa    => 1
                                    );
   --
exception
   when others then
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_reg_log_despr_integr fase ('||vn_fase||'): '||sqlerrm);
end pkb_reg_log_despr_integr;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Inventário
------------------------------------------------------------------------------------------
procedure pkb_despr_inventario ( en_empresa_id in empresa.id%Type
                               , en_usuario_id in neo_usuario.id%type
                               , ed_dt_ini     in date
                               , ed_dt_fin     in date
                               )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              inventario.id%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_inv (en_multorg_id mult_org.id%type) is
   select i.id
        , i.empresa_id
        , i.dt_ref
     from empresa     e
        , usuario_empresa ue
        , inventario  i
    where e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and i.empresa_id = nvl(en_empresa_id, i.empresa_id)
      and i.empresa_id = e.id
      and trunc(i.dt_inventario) between trunc(ed_dt_ini) and trunc(ed_dt_fin);
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Inventário.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '2' ); -- Inventário
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 3;
      --
      for rec in c_inv (vn_multorg_id) loop
         exit when c_inv%notfound or (c_inv%notfound) is null;
         --
         vn_fase := 4;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_ref > vd_dt_ult_fecha then
            --
            vn_fase := 6;
            --
            vn_id := rec.id;
            --
            vn_fase := 6.1;
            --
            delete 
			  from r_loteintws_inventario 
			 where inventario_id = rec.id;
            --
            vn_fase := 6.2;
            --
            delete 
              from invent_cst 
             where inventario_id = rec.id;
            --
            vn_fase := 6.3;
            --
            --#75210 Inclusao de tabela limpeza
            delete 
              from invent_inf_comp_merc_st
             where inventario_id = rec.id;
            --
            vn_fase := 7;
            --
            delete from inventario where id = rec.id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do inventário não permitido devido a data '||
                                                                    'de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Inventário (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_inventario): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_inventario fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_inventario;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Cupom Fiscal
------------------------------------------------------------------------------------------
procedure pkb_despr_cupom_fiscal ( en_empresa_id in empresa.id%Type
                                 , en_usuario_id in neo_usuario.id%type
                                 , ed_dt_ini     in date
                                 , ed_dt_fin     in date
                                 )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              nota_fiscal.id%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_redz (en_multorg_id mult_org.id%type) is
   select r.id
        , ee.empresa_id
        , r.dt_doc
     from reducao_z_ecf r
        , equip_ecf     ee
        , empresa       e
        , usuario_empresa ue
    where e.multorg_id    = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and ee.empresa_id   = nvl(en_empresa_id, ee.empresa_id)
      and ee.empresa_id   = e.id
      and r.equipecf_id   = ee.id
      and trunc(r.dt_doc) between trunc(ed_dt_ini) and trunc(ed_dt_fin);
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Cupom Fiscal.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '3' ); -- Cupom Fiscal
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 3;
      --
      for rec in c_redz (vn_multorg_id) loop
         exit when c_redz%notfound or (c_redz%notfound) is null;
         --
         vn_fase := 4;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_doc > vd_dt_ult_fecha then
            --
            vn_fase := 6;
            --
            vn_id := rec.id;
            --
            pk_csf_api_ecf.pkb_excluir_reducao_z_ecf ( en_reducaozecf_id => rec.id );
            --
            vn_fase := 7;
            --
            delete from r_loteintws_redzecf where reducaozecf_id = rec.id;
            --
            vn_fase := 7.1;
            --
            delete from reducao_z_ecf where id = rec.id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do cupom fiscal não permitido devido a '||
                                                                    'data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Cupom Fiscal - Redução Z (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_cupom_fiscal): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_cupom_fiscal fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_cupom_fiscal;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar o conhecimento de transporte de Terceiros
------------------------------------------------------------------------------------------
procedure pkb_despr_conhec_transp ( en_empresa_id in empresa.id%Type
                                  , en_usuario_id in neo_usuario.id%type
                                  , ed_dt_ini     in date
                                  , ed_dt_fin     in date
                                  )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              conhec_transp.id%type;
   vn_nro_ct          conhec_transp.nro_ct%type;
   vv_serie           conhec_transp.serie%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   vn_dm_ind_emit     number;
   vv_texto           varchar2(100);
   vb_reinf_r2010     boolean ;
   vb_reinf_r2020     boolean;
   --
   --
   cursor c_ct (en_multorg_id mult_org.id%type, en_dm_ind_emit in number) is
   select ct.id
        , ct.nro_ct
        , ct.serie
        , ct.empresa_id
        , ct.dt_sai_ent
        , ct.dt_hr_emissao
        , ct.dm_ind_emit
        , ct.dm_st_proc
     from empresa e
        , usuario_empresa ue
        , conhec_transp ct
    where e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and ct.empresa_id = e.id
      and trunc(nvl(ct.dt_sai_ent, ct.dt_hr_emissao)) between trunc(ed_dt_ini) and trunc(ed_dt_fin)
      and ct.dm_ind_emit     = nvl(en_dm_ind_emit, ct.dm_ind_emit)
      and ct.empresa_id      = nvl(en_empresa_id, ct.empresa_id)
      and ct.dm_arm_cte_terc = 0
    order by ct.id;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr = '1' then --|Emissão própria|--
      --
      vn_dm_ind_emit := 0;
      --
      vv_texto := 'Conhecimento de Transporte - Emissão Própria.';
      --
   elsif gv_cd_tipo_obj_integr = '2' then --|Emissão de terceiros|--
      --
      vn_dm_ind_emit := 1;
      --
      vv_texto := 'Conhecimento de Transporte - Emissão de Terceiros.';
      --
   elsif gv_cd_tipo_obj_integr = '3' or gv_cd_tipo_obj_integr is null  then --|Cancelamento|--
      --
      vn_dm_ind_emit := null;
      --
      vv_texto := 'Conhecimento de Transporte.';
      --
   end if;
   --
   vn_fase := 1.2;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1.3;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '4' ); -- Conhecimento de Transporte
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 3;
      --
      for rec in c_ct (vn_multorg_id, vn_dm_ind_emit) loop
         exit when c_ct%notfound or (c_ct%notfound) is null;
         --
         vn_fase := 3.1; -- conhecimento de transporte não poderá ser excluído
         --
         vn_nro_ct := rec.nro_ct;
         --
         if rec.dm_ind_emit = 0  and -- conhecimento de transporte de emissão própria
            rec.dm_st_proc  = 8 then -- conhecimento de transporte inutilizada
            --
            vn_fase := 3.2; -- conhecimento de transporte não poderá ser excluído
            --
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'O Conhec. Transporte Nro:'||vn_nro_ct||' está inutilizado.'||
                                                                    'O conhecimento não pode ser excluído.'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
             --
         else
             --
             vn_fase := 4;
             --
             if nvl(en_empresa_id,0) = 0 then
                --
                vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                           , vn_objintegr_id ) -- en_objintegr_id
                                     , (ed_dt_ini - 1));
                --
             end if;
             --
             vn_fase := 5;
             --
             if vd_dt_ult_fecha is null or
                nvl(rec.dt_sai_ent,rec.dt_hr_emissao) > vd_dt_ult_fecha then
                --
                vn_fase := 6;
                --
                vn_id     := rec.id;
                vv_serie  := rec.serie;
                --
                vb_reinf_r2010:= pk_csf_ct.fkg_existe_reinf_r2010_ct(en_conhectransp_id=> rec.id);
                vb_reinf_r2020:= pk_csf_ct.fkg_existe_reinf_r2020_ct(en_conhectransp_id=> rec.id);
                --
                -- Se não houver envolvimento com os eventos R-2010 e R-2020 do Reinf, o processo de exclusão irá prosseguir normalmente.
                if vb_reinf_r2010 = false and vb_reinf_r2020 = false then
                  --
                  pk_csf_api_d100.pkb_excluir_dados_ct ( en_conhectransp_id   => rec.id
                                                       , en_excl_rloteintwsct => 1 );
                  --
                  pk_csf_api_ct.pkb_excluir_dados_ct ( en_conhectransp_id   => rec.id
                                                     , en_excl_rloteintwsct => 1 );
                  --
                  vn_fase := 7;
                  --
                  delete from conhec_transp where id = rec.id;
                  --
                else
                  ---
                  vn_fase := 7.1;
                  ---
                  if vb_reinf_r2010 = true then
                    ---
                    pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                     , ev_mensagem       => 'Desprocessar Integração'
                                                     , ev_resumo         => 'O Conhec. Transporte Nro:'||vn_nro_ct||' está relacionado ao Evento R-2010 do REINF.'||
                                                                            'Favor realizar a exclusão deste conhec. transporte no REINF.'
                                                     , en_tipo_log       => info_fechamento
                                                     , en_referencia_id  => null
                                                     , ev_obj_referencia => 'DESPR_INTEGR'
                                                     , en_empresa_id     => gn_empresa_id
                                                     );
                    ---
                  end if;
                  ---
                  vn_fase := 7.2;
                  ---
                  if vb_reinf_r2020 = true then
                    ---
                    pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                     , ev_mensagem       => 'Desprocessar Integração'
                                                     , ev_resumo         => 'O Conhec. Transporte Nro:'||vn_nro_ct||' está relacionado ao Evento R-2020 do REINF.'||
                                                                            'Favor realizar a exclusão deste conhec. transporte no REINF.'
                                                     , en_tipo_log       => info_fechamento
                                                     , en_referencia_id  => null
                                                     , ev_obj_referencia => 'DESPR_INTEGR'
                                                     , en_empresa_id     => gn_empresa_id
                                                     );
                     ---
                  end if;
                  ---
                end if;
                --
             else
                --
                vn_fase := 8;
                -- Gerar log no agendamento devido a data de fechamento
                pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                 , ev_mensagem       => 'Desprocessar Integração'
                                                 , ev_resumo         => 'Período informado para desprocessar a integração do conhecimento de transporte não permitido '||
                                                                        'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                 , en_tipo_log       => info_fechamento
                                                 , en_referencia_id  => null
                                                 , ev_obj_referencia => 'DESPR_INTEGR'
                                                 , en_empresa_id     => gn_empresa_id
                                                 );
                --
             end if;
             --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o Conhecimento de Transporte (id = '||vn_id||', nro = '||vn_nro_ct||', série = '||vv_serie||'). Verifique '||
                   '(pk_despr_integr.pkb_despr_conhec_transp): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_conhec_transp fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_conhec_transp;

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar o Cupom Sat
------------------------------------------------------------------------------------------

procedure pkb_despr_cupom_fiscal_sat ( en_empresa_id in empresa.id%Type
                                  , en_usuario_id in neo_usuario.id%type
                                  , ed_dt_ini     in date
                                  , ed_dt_fin     in date
                                  )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              cupom_fiscal.id%type;
   vn_nro_cfe          cupom_fiscal.nro_cfe%type;
   vv_serie           cupom_fiscal.nro_serie_sat%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   vv_texto           varchar2(100);
   --
   --
   cursor c_cf (en_multorg_id mult_org.id%type) is
   select cf.id
        , cf.nro_cfe
        , cf.nro_serie_sat
        , cf.empresa_id
        , to_date(cf.dt_hr_autoriz,'DD/MM/YYYY') as dt_hr_autoriz
        , cf.dt_emissao
     from empresa e
        , usuario_empresa ue
        , cupom_fiscal cf
    where e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and cf.empresa_id = e.id
      and trunc(nvl(to_date(cf.dt_hr_autoriz,'DD/MM/YYYY'), cf.dt_emissao)) between trunc(ed_dt_ini) and trunc(ed_dt_fin)
      and cf.empresa_id      = nvl(en_empresa_id, cf.empresa_id)
    order by cf.id;
 --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   vn_fase := 1.2;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1.3;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '12' ); -- Cupom Sat
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 3;
      --
      for rec in c_cf (vn_multorg_id) loop
         exit when c_cf%notfound or (c_cf%notfound) is null;
         --
         vn_fase := 4;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            nvl(rec.dt_hr_autoriz,rec.dt_emissao) > vd_dt_ult_fecha then
            --
            vn_fase := 6;
            --
            vn_id     := rec.id;
            vn_nro_cfe := rec.nro_cfe;
            vv_serie  := rec.nro_serie_sat;
            --
              vn_fase := 6.1;
              --
              delete from r_loteintws_cupomsat where cupomfiscal_id = rec.id;
              --
              vn_fase := 6.2;
              --
              delete from cupom_fiscal_total where cupomfiscal_id = rec.id;
              --
              vn_fase := 6.3;
              --
              delete from imp_itemcf where itemcupomfiscal_id in (select id from item_cupom_fiscal where cupomfiscal_id = rec.id );
              --
              vn_fase := 6.4;
              --
              delete from  item_cupom_fiscal where cupomfiscal_id = rec.id;
              --
              vn_fase := 6.5;
              --
              delete from cupom_fiscal where id = rec.id;        
              --
              vn_fase := 7.1;

              --
           -- end if;
            --
         else             --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Cupom Sat não permitido '||
                                                                    'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o Cupom Sat (id = '||vn_id||', nro = '||vn_nro_cfe||', série = '||vv_serie||'). Verifique '||
                   '(pk_despr_integr.pkb_despr_cupom_fiscal_sat): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_cupom_fiscal_sat fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_cupom_fiscal_sat;




------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Nota Fiscal de Serviço Contínuo
------------------------------------------------------------------------------------------
procedure pkb_despr_nf_serv_cont ( en_empresa_id in empresa.id%Type
                                 , en_usuario_id in neo_usuario.id%type
                                 , ed_dt_ini     in date
                                 , ed_dt_fin     in date
                                 )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              nota_fiscal.id%type;
   vn_nro_nf          nota_fiscal.nro_nf%type;
   vv_serie           nota_fiscal.serie%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_nf (en_multorg_id mult_org.id%type) is
   select nf.id
        , nf.nro_nf
        , nf.serie
        , nf.empresa_id
        , nf.dt_sai_ent
        , nf.dt_emiss
     from empresa e
        , usuario_empresa ue
        , nota_fiscal nf
        , mod_fiscal mf
    where e.multorg_id       = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and nf.empresa_id      = e.id
      and trunc(nvl(nf.dt_sai_ent, nf.dt_emiss)) between trunc(ed_dt_ini) and trunc(ed_dt_fin)
      and nf.dm_ind_emit     = 1 -- Terceiros
      and nf.dm_arm_nfe_terc = 0
      and nf.empresa_id      = nvl(en_empresa_id, nf.empresa_id)
      and nf.dm_st_proc not in (0, 1, 2, 3, 14, 18, 19, 21) -- 0-Não validada, 1-Não Processada. Aguardando Processamento, 2-Processada. Aguardando Envio, 3-Enviada ao SEFAZ. Aguardando Retorno, 14-Sefaz em contingência, 18-Digitada, 19-Processada e 21-Aguardando Liberação
      and mf.id              = nf.modfiscal_id
      and mf.cod_mod        in ('06', '21', '22', '28', '29');
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Nota Fiscal de Serviço Contínuo.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '5' ); -- Notas fiscais de Serviço Contínuo
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 3;
      --
      for rec in c_nf (vn_multorg_id) loop
         exit when c_nf%notfound or (c_nf%notfound) is null;
         --
         vn_fase := 4;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            nvl(rec.dt_sai_ent,rec.dt_emiss) > vd_dt_ult_fecha then
            --
            vn_fase := 6;
            --
            vn_id     := rec.id;
            vn_nro_nf := rec.nro_nf;
            vv_serie  := rec.serie;
            --
            pk_csf_api.pkb_excluir_dados_nf(rec.id);
            --
            vn_fase := 6.1;
            --
            delete from r_loteintws_nf where notafiscal_id = rec.id;
            --
            vn_fase := 7;
            --
            delete from nota_fiscal where id = rec.id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração da nota fiscal de serviço contínuo não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', série = '||vv_serie||') fase(' || vn_fase || '). Verifique se a mesma não está '||
                   'vinculada aos processos: EFD-Contribuições - Bloco 1500 e/ou 1100; Pagamento de Impostos - DCTF; Apuração e/ou Sub-Apuração de ICMS; '||
                   'Informações sobre Exportação; e ainda, Recebimento de Download de XML (pk_despr_integr.pkb_despr_nf_serv_cont): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_nf_serv_cont fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_nf_serv_cont;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Nota Fiscal Mercantil
------------------------------------------------------------------------------------------
procedure pkb_despr_nota_fiscal ( en_empresa_id in empresa.id%Type
                                , en_usuario_id in neo_usuario.id%type
                                , ed_dt_ini     in date
                                , ed_dt_fin     in date
                                )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              nota_fiscal.id%type;
   vn_nro_nf          nota_fiscal.nro_nf%type;
   vv_serie           nota_fiscal.serie%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   vn_dm_ind_emit     number;
   vv_texto           varchar2(100);
   vn_empresa_id      number;
   vn_exist           number;
   vn_det_info        number;
   --
   vb_reinf_r2010     boolean;
   vb_reinf_r2020     boolean;
   --
   cursor c_nf (en_multorg_id mult_org.id%type, en_dm_ind_emit in number) is
   select nf.id
        , nf.nro_nf
        , nf.serie
        , nf.empresa_id
        , nf.dt_sai_ent
        , nf.dt_emiss
        , nf.dm_ind_emit
        , nf.dm_st_proc
     from empresa     e
        , usuario_empresa ue
        , nota_fiscal nf
        , mod_fiscal mf
    where e.multorg_id       = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and nf.empresa_id      = e.id
      and trunc(nvl(nf.dt_sai_ent, nf.dt_emiss)) between trunc(ed_dt_ini) and trunc(ed_dt_fin)
      and nf.dm_arm_nfe_terc = 0
      and nf.empresa_id      = nvl(en_empresa_id, nf.empresa_id)
      and nf.dm_ind_emit     = nvl(en_dm_ind_emit, nf.dm_ind_emit)
      and nf.nfe_proc_xml   is null
      and nf.dm_st_proc not in (0, 1, 2, 3, 14, 18, 19, 21) -- 0-Não validada, 1-Não Processada. Aguardando Processamento, 2-Processada. Aguardando Envio, 3-Enviada ao SEFAZ. Aguardando Retorno, 14-Sefaz em contingência, 18-Digitada, 19-Processada e 21-Aguardando Liberação
      and mf.id              = nf.modfiscal_id
      and mf.cod_mod        in ('01', '04', '1B', '55', '65');
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr = '1' then
      --
      vn_dm_ind_emit := 0;
      --
      vv_texto := 'Notas Fiscais Mercantis - Emissão Própria.';
      --
   elsif gv_cd_tipo_obj_integr in('2','4') or gv_cd_tipo_obj_integr is null then
      --
      vn_dm_ind_emit := null;
      --
      vv_texto := 'Notas Fiscais Mercantis.';
      --
   elsif gv_cd_tipo_obj_integr = '3' then
      --
      vn_dm_ind_emit := 1;
      --
      vv_texto := 'Notas Fiscais Mercantis - Terceiros.';
      --
   elsif gv_cd_tipo_obj_integr = '5' then
      --
      --|Valores -1 por conta de que esse tipo de objeto(Retorna XML de NFe) não pode sofrer alterações.
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   end if;
   --
   vn_fase := 2;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(vn_empresa_id,0) > 0 then
      --
      vn_fase := 3;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 4;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '6' ); -- Notas fiscais Mercantis
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 5;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 6;
      --
      for rec in c_nf (vn_multorg_id, vn_dm_ind_emit)
      loop
         --
         exit when c_nf%notfound or (c_nf%notfound) is null;
         --
         vn_fase := 7;
         --
         if rec.dm_ind_emit = 0 and -- nota fiscal de emissão própria
            rec.dm_st_proc = 8 then -- nota fiscal inutilizada
            --
            vn_fase := 8; -- nota não poderá ser excluída
            --
         else
            --
            vn_fase := 9;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            vn_fase := 10;
            --
            if vd_dt_ult_fecha is null or
               nvl(rec.dt_sai_ent,rec.dt_emiss) > vd_dt_ult_fecha then
               --
               vn_fase := 11;
               --
               vn_id     := rec.id;
               vn_nro_nf := rec.nro_nf;
               vv_serie  := rec.serie;
               --
               -- Verificar se está nota possui algum tipo de Geração de
               -- Pagamentos de Impostos Retidos
               vn_exist := null;
               --
               begin
                  --
                  select count(1)
                    into vn_exist
                    from item_nota_fiscal inf
                       , imp_itemnf       ii
                       , det_ger_pgto_imp_ret dgp
                   where inf.notafiscal_id = rec.id
                     and ii.itemnf_id      = inf.id
                     and dgp.impitemnf_id  = ii.id;
                  --
               exception
                 when others then
                   vn_exist := null;
               end;
               --
               vn_fase := 12;
               --
               -- Verificar se a nota possui algum vínculo com
               -- detalhes de geração de informação de exportação.
               --
               vn_det_info := null;
               --
               begin
                  --
                  select count(1)
                    into vn_det_info
                    from infor_export_nota_fiscal ie
                       , det_ger_infor_export     dg
                   where ie.notafiscal_id            = rec.id
                     and dg.inforexportnotafiscal_id = ie.id;
                  --
               exception
                  when others then
                     --
                     vn_det_info := null;
                     --
               end;
               --
               vn_fase := 13;
               --
               if nvl(vn_exist, 0) = 0 and nvl(vn_det_info, 0) = 0 then
                  --
                  vn_fase := 13.1;
                  vb_reinf_r2010:= pk_csf.fkg_existe_reinf_r2010_nf (en_notafiscal_id => rec.id);
                  vb_reinf_r2020:= pk_csf.fkg_existe_reinf_r2020_nf (en_notafiscal_id => rec.id);
                  --
                  if vb_reinf_r2010 = false and vb_reinf_r2020 = false then
                    --
                    begin
                       --
                       vn_fase := 14;
                       --
                       begin
                          update cons_nfe_dest cn
                             set cn.notafiscal_id = null
                           where cn.notafiscal_id = rec.id;
                       exception
                          when others then
                             --
                             rollback;
                             --
                             vv_resumo := 'Problemas ao anular o identificador da Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', série = '||vv_serie||
                                          '). Verifique o processo de consulta de nota fiscal de destinatário (tabela cons_nfe_dest). Erro = '||sqlerrm;
                             --
                             pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                              , ev_mensagem       => 'Desprocessar Integração'
                                                              , ev_resumo         => vv_resumo
                                                              , en_tipo_log       => informacao
                                                              , en_referencia_id  => vn_id
                                                              , ev_obj_referencia => 'DESPR_INTEGR'
                                                              , en_empresa_id     => gn_empresa_id
                                                              , en_dm_impressa    => 1
                                                              );
                             --
                             raise_application_error(-20101, 'Problemas ao anular o identificador da Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||
                                                             ', série = '||vv_serie||'). Verifique o processo de consulta de nota fiscal de destinatário '||
                                                             '(tabela cons_nfe_dest). Erro na pk_despr_integr.pkb_despr_nota_fiscal fase ('||vn_fase||'): '||
                                                             sqlerrm);
                             --
                       end;
                       --
                       vn_fase := 16;
                       --
                       begin
                          update nfe_download_xml nd
                             set nd.notafiscal_id = null
                           where nd.notafiscal_id = rec.id;
                       exception
                          when others then
                             --
                             rollback;
                             --
                             vv_resumo := 'Problemas ao anular o identificador da Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', série = '||vv_serie||
                                          '). Verifique o processo de download de XML (tabela nfe_download_xml). Erro = '||sqlerrm;
                             --
                             pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                              , ev_mensagem       => 'Desprocessar Integração'
                                                              , ev_resumo         => vv_resumo
                                                              , en_tipo_log       => informacao
                                                              , en_referencia_id  => vn_id
                                                              , ev_obj_referencia => 'DESPR_INTEGR'
                                                              , en_empresa_id     => gn_empresa_id
                                                              , en_dm_impressa    => 1
                                                              );
                             --
                             raise_application_error(-20101, 'Problemas ao anular o identificador da Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', '||
                                                             'série = '||vv_serie||'). Verifique o processo de download de XML (tabela nfe_download_xml). Erro '||
                                                             'na pk_despr_integr.pkb_despr_nota_fiscal fase ('||vn_fase||'): '||sqlerrm);
                          --
                       end;
                       --
                       vn_fase := 17;
                       --
                       pk_csf_api.pkb_excluir_dados_nf(rec.id);
                       --
                       vn_fase := 18;
                       --
                       delete from r_loteintws_nf where notafiscal_id = rec.id;
                       --
                       vn_fase := 19;
                       --
                       delete from nota_fiscal nf where nf.id = rec.id;
                       --
                    exception
                       when others then
                          --
                          rollback;
                          --
                          vv_resumo := 'Problemas ao excluir a Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', série = '||vv_serie||'). Verifique se a '||
                                       'mesma não está vinculada aos processos: EFD-Contribuições - Bloco 1500 e/ou 1100; Pagamento de Impostos - DCTF; Apuração '||
                                       'e/ou Sub-Apuração de ICMS; Informações sobre Exportação; Recebimento de Download de XML; e ainda, Integração via Web '||
                                       'Service (pk_despr_integr.pkb_despr_nota_fiscal): '||sqlerrm;
                          --
                          pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                           , ev_mensagem       => 'Desprocessar Integração'
                                                           , ev_resumo         => vv_resumo
                                                           , en_tipo_log       => informacao
                                                           , en_referencia_id  => vn_id
                                                           , ev_obj_referencia => 'DESPR_INTEGR'
                                                           , en_empresa_id     => gn_empresa_id
                                                           , en_dm_impressa    => 1
                                                           );
                          --
                          raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_nota_fiscal fase ('||vn_fase||'): '||sqlerrm);
                          --
                    end;
                    --
                  else
                    ---
                    vn_fase := 7.1;
                    ---
                    if vb_reinf_r2010 = true then
                      ---
                      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                       , ev_mensagem       => 'Desprocessar Integração'
                                                       , ev_resumo         => 'A Nota Fiscal Nro:'||vn_nro_nf||' está relacionado ao Evento R-2010 do REINF.'||
                                                                              'Favor realizar a exclusão desta nota fiscal no REINF.'
                                                       , en_tipo_log       => informacao
                                                       , en_referencia_id  => vn_id
                                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                                       , en_empresa_id     => gn_empresa_id
                                                       , en_dm_impressa    => 1
                                                       );
                      ---
                    end if;
                    ---
                    vn_fase := 7.2;
                    ---
                    if vb_reinf_r2020 = true then
                      ---
                      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                       , ev_mensagem       => 'Desprocessar Integração'
                                                       , ev_resumo         => 'A Nota Fiscal Nro:'||vn_nro_nf||' está relacionado ao Evento R-2020 do REINF.'||
                                                                              'Favor realizar a exclusão desta nota fiscal no REINF.'
                                                       , en_tipo_log       => informacao
                                                       , en_referencia_id  => vn_id
                                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                                       , en_empresa_id     => gn_empresa_id
                                                       , en_dm_impressa    => 1
                                                       );
                       ---
                    end if;
                    ---
                  end if;
                  --
               else
                  --
                  vn_fase := 20;
                  --
                  vv_resumo := 'Não pode ser desprocessada a Nota Fiscal ( Nro: '|| vn_nro_nf || ' e Serie: '|| vv_serie ||'). ';
                  --
                  if vn_exist is not null then
                     --
                     vv_resumo := vv_resumo || 'Nota vinculada com "Geração de Pagamentos de Impostos Retidos", favor verificar na tela Sped '||
                                               '-> Impostos Retidos -> Geração de Pagamento de Impostos Retidos.';
                     --
                  end if;
                  --
                  vn_fase := 21;
                  --
                  if vn_det_info is not null then
                     --
                     vv_resumo :=  vv_resumo || 'Nota vinculada com "Detalhe da geração de informações sobre exportação".'||
                                                'Favor verificar na tela Sped -> ICMS/IPI -> Informação sobre Exportação.';
                     --
                  end if;
                  --
                  vn_fase := 22;
                  --
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => vv_resumo
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => vn_id
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => nvl(gn_empresa_id,en_empresa_id)
                                                   , en_dm_impressa    => 1
                                                   );
                  --
               end if;
               --
            else
               --
               vn_fase := 23;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração da nota fiscal mercantil não permitido '||
                                                                       'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if; -- período de fechamento
            --
         end if; -- nota fiscal de emissão própria e nota fiscal inutilizada - não deve ser excluída
         --
      end loop;
      --
      vn_fase := 24;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', série = '||vv_serie||', fase = '||vn_fase||'). Verifique se a '||
                   'mesma não está vinculada aos processos: EFD-Contribuições - Bloco 1500 e/ou 1100; Pagamento de Impostos - DCTF; Apuração e/ou Sub-'||
                   'Apuração de ICMS; Informações sobre Exportação; e ainda, Recebimento de Download de XML (pk_despr_integr.pkb_despr_nota_fiscal): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_nota_fiscal fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_nota_fiscal;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Nota Fiscal Serviço EFD
------------------------------------------------------------------------------------------
procedure pkb_despr_nf_serv_efd ( en_empresa_id in empresa.id%Type
                                , en_usuario_id in neo_usuario.id%type
                                , ed_dt_ini     in date
                                , ed_dt_fin     in date
                                )
is
   --
   PRAGMA                      AUTONOMOUS_TRANSACTION;
   vn_fase                     number := 0;
   vn_id                       nota_fiscal.id%type;
   vn_nro_nf                   nota_fiscal.nro_nf%type;
   vv_serie                    nota_fiscal.serie%type;
   vn_objintegr_id             obj_integr.id%type;
   vd_dt_ult_fecha             fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id           log_generico.id%type;
   vn_multorg_id               mult_org.id%type;
   vn_lotenfs_id               lote_nfs.id%type;
   vn_rnfestrarqimportnfse_id  r_nf_estrarqimportnfse.id%type;
   --
   vn_dm_ind_emit     number;
   vv_texto           varchar(100);
   vn_qtd_nd          number := 0;
   vn_qtd_reinf       number := 0;
   --
   cursor c_nf (en_multorg_id mult_org.id%type, en_dm_tipo_emit in number) is
   select nf.id
        , nf.nro_nf
        , nf.serie
        , nf.empresa_id
        , nf.dt_sai_ent
        , nf.dt_emiss
     from empresa e
        , usuario_empresa ue
        , nota_fiscal nf
        , mod_fiscal mf
    where e.multorg_id       = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and nf.empresa_Id      = e.id
      and trunc(nvl(nf.dt_sai_ent, nf.dt_emiss)) between trunc(ed_dt_ini) and trunc(ed_dt_fin)
      and nf.nfe_proc_xml   is null
      and nf.dm_arm_nfe_terc = 0
      and nf.empresa_id      = nvl(en_empresa_id, nf.empresa_id)
      and nf.dm_ind_emit     = nvl(en_dm_tipo_emit, nf.dm_ind_emit)
      and nf.dm_st_proc not in (0, 1, 2, 3, 14, 18, 19, 21) -- 0-Não validada, 1-Não Processada. Aguardando Processamento, 2-Processada. Aguardando Envio, 3-Enviada ao SEFAZ. Aguardando Retorno, 14-Sefaz em contingência, 18-Digitada, 19-Processada e 21-Aguardando Liberação
      and mf.id              = nf.modfiscal_id
      and mf.cod_mod        in ('99', 'ND')
    order by 1 desc;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr = '1' then
      --
      vn_dm_ind_emit := 0;
      --
      vv_texto := 'Notas Fiscais de Serviço - Emissão Própria.';
      --
   elsif gv_cd_tipo_obj_integr = '2' or gv_cd_tipo_obj_integr is null then
      --
      vn_dm_ind_emit := null;
      --
      vv_texto := 'Notas Fiscais de Serviço.';
      --
   elsif gv_cd_tipo_obj_integr = '3' then
      --
      vn_dm_ind_emit := 1;
      --
      vv_texto := 'Notas Fiscais de Serviço - Emissão de Terceiros.';
      --
   end if;
   --
   vn_fase := 1.2;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1.3;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '7' ); -- Notas fiscais de Serviço
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      for rec in c_nf (vn_multorg_id, vn_dm_ind_emit) loop
         exit when c_nf%notfound or (c_nf%notfound) is null;
         --
         begin
            --
            select count(*)
              into vn_qtd_nd
              from ddof100_nfnd
             where notafiscal_id = rec.id;
            --
         exception
            when others then
               --
               vn_qtd_nd := 0;
               --
         end;
         --
         vn_qtd_reinf := null;
         -- Verificar se a Nota ja foi enviada para Declaração do EFD-REINF.
         begin
            --
            select distinct 1
              into vn_qtd_reinf
              from efd_reinf_r2020 e
                 , efd_reinf_r2020_nf enf
             where e.id = enf.efdreinfr2020_id
               and enf.notafiscal_id = rec.id;
            --
         exception
          when others then
            vn_qtd_reinf := null;
         end;
         --
         if nvl(vn_qtd_reinf,0) = 0 then
            --
            begin
               --
               select distinct 1
                 into vn_qtd_reinf
                 from efd_reinf_r2010 e
                    , efd_reinf_r2010_nf enf
                where e.id = enf.efdreinfr2010_id
                  and enf.notafiscal_id = rec.id;
               --
            exception
             when others then
               vn_qtd_reinf := null;
            end;
            --
         end if;
         --
         vn_fase := 4.1;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if nvl(vn_qtd_nd, 0) = 0
          and nvl(vn_qtd_reinf,0) = 0 then
            --
            if vd_dt_ult_fecha is null or
            nvl(rec.dt_sai_ent,rec.dt_emiss) > vd_dt_ult_fecha then
               --
               vn_fase := 6;
               --
               vn_id     := rec.id;
               vn_nro_nf := rec.nro_nf;
               vv_serie  := rec.serie;
               vn_lotenfs_id := null;
               --
               vn_fase := 6.1;
               --
               begin
                  --
                  select lotenfs_id
                    into vn_lotenfs_id
                    from nf_compl_serv
                   where notafiscal_id = rec.id;
                  --
               exception
                  when others then
                     vn_lotenfs_id := 0;
               end;
               --
               vn_rnfestrarqimportnfse_id := 0;
               --
               begin
                  --
                  select 1
                    into vn_rnfestrarqimportnfse_id
                    from r_nf_estrarqimportnfse
                   where notafiscal_id = rec.id;
                  --
               exception
                 when others then
                     vn_rnfestrarqimportnfse_id := 0;
               end;
               --
               vn_fase := 7;
               --
               if nvl(vn_lotenfs_id,0) <= 0
                and nvl(vn_rnfestrarqimportnfse_id,0) <= 0 then
                  --
                  pk_csf_api.pkb_excluir_dados_nf(rec.id);
                  --
                  vn_fase := 7.1;
                  --
                  delete from r_loteintws_nf where notafiscal_id = rec.id;
                  --
                  vn_fase := 7.2;
                  --
                  delete from nota_fiscal where id = rec.id;
                  --
               end if;
               --
            else
               --
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração da nota fiscal de serviço não permitido '||
                                                                       'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         else
            --
            vn_fase := 8;
            --
            if nvl(vn_qtd_nd,0) > 0 then
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Não permitido a exclusão de Nota de Débito. Desprocessar "Geração dos créditos de '||
                                                                       'PIS/COFINS - Notas Fiscais de Débito e Bloco F100".'
                                                , en_tipo_log       => informacao
                                                , en_referencia_id  => 1
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
            vn_fase := 9;
            --
            if nvl(vn_qtd_reinf,0) > 0 then
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Neste periodo solicitado a Nota Fiscal NRO_NF: '|| rec.nro_nf ||', SERIE: '|| rec.serie ||
                                                                       ' não poderá ser excluida pois existem evento enviado para EFD-REINF declarando esta informação, favor Verificar.'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a Nota Fiscal (id = '||vn_id||', nro = '||vn_nro_nf||', série = '||vv_serie||'). Verifique se a mesma não está '||
                   'vinculada aos processos: EFD-Contribuições - Bloco 1500 e/ou 1100; Pagamento de Impostos - DCTF; Apuração e/ou Sub-Apuração de ICMS; '||
                   'Informações sobre Exportação; e ainda, Recebimento de Download de XML (pk_despr_integr.pkb_despr_nf_serv_efd): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_nf_serv_efd fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_nf_serv_efd;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar o DIMOB
------------------------------------------------------------------------------------------
procedure pkb_despr_dimob ( en_empresa_id in empresa.id%type
                          , en_usuario_id in neo_usuario.id%type
                          , ed_dt_ini     in date
                          , ed_dt_fin     in date
                          )
is
   --
   vt_log_generico        dbms_sql.number_table;
   vn_fase                number := null;
   vn_multorg_id          mult_org.id%type;
   vn_loggenerico_id      log_generico.id%type;
   vn_objintegr_id        obj_integr.id%type;
   vd_dt_ult_fecha        fecha_fiscal_empresa.dt_ult_fecha%type;
   vd_dt_ult_fecha2       number := null;
   vn_id                  inf_bloco_i_pc.id%type;
   --
   vn_empresa_id          number;
   --
   cursor c_loc (en_multorg_id mult_org.id%type) is
   select l.id
        , l.empresa_id
        --, to_date(l.dt_contrato,'dd/mm/rrrr') dt_ref
        ,l.ano_ref as dt_ref
     from locacao l
        , empresa e
        , usuario_empresa ue
    where  l.ano_ref between TO_CHAR(ed_dt_ini,'YYYY') and TO_CHAR(ed_dt_fin,'YYYY')
      and l.empresa_id = nvl(en_empresa_id,l.empresa_id)
      and e.id = l.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id ;

   cursor c_constr (en_multorg_id mult_org.id%type) is
   select f.id
        , f.empresa_id
        --, to_date(f.dt_contrato,'dd/mm/rrrr') dt_ref
        ,f.ano_ref as dt_ref
     from ficha_incorp_constr f
        , empresa e
        , usuario_empresa ue
    where f.ano_ref between TO_CHAR(ed_dt_ini,'YYYY') and TO_CHAR(ed_dt_fin,'YYYY')
      and f.empresa_id = nvl(en_empresa_id,f.empresa_id)
      and e.id = f.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;

   cursor c_venda ( en_multorg_id mult_org.id%type) is
   select f.id
        , f.empresa_id
        --, to_date(f.dt_contrato,'dd/mm/rrrr') dt_ref
        ,f.ano_ref as dt_ref
     from ficha_interm_venda f
        , empresa e
        , usuario_empresa ue
    where f.ano_ref between TO_CHAR(ed_dt_ini,'YYYY') and TO_CHAR(ed_dt_fin,'YYYY')
      and f.empresa_id = nvl(en_empresa_id,f.empresa_id)
      and e.id = f.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr = '1' then
      --
      -- Locação de imoveis.
      --
      if nvl(vn_multorg_id,0) > 0
         or nvl(en_empresa_id,0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'DIMOB - Locação de Imóveis.'
                                  );
         --
         vn_fase := 2;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '52' ); -- DIMOB
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         for rec in c_loc (vn_multorg_id) loop
            exit when c_loc%notfound or (c_loc%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            select   SUBSTR(vd_dt_ult_fecha, '7')
            into vd_dt_ult_fecha2
             from dual;
            --
            if vd_dt_ult_fecha2 is null or
               rec.dt_ref > vd_dt_ult_fecha2 then
               --
               delete from det_valor_locacao
                where locacao_id = rec.id;
               --
               vn_fase := 3;
               --
               delete from r_loteintws_locacao where locacao_id = rec.id;
               --
               vn_fase := 4;
               --
               delete from locacao where id = rec.id;
               --
               commit;
               --
            else
               --
               vn_fase := 5;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração do DIMOB não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'LOCACAO'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
      end if;
      --
      commit;
      --
      -- Garante que apenas o tipo de objeto em questão seja desprocessado.
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   elsif gv_cd_tipo_obj_integr = '2' then
      --
      -- Incorporação de construção de imoveis.
      --
      if nvl(vn_multorg_id,0) > 0
         or nvl(en_empresa_id,0) > 0 then
         --
         -- Registra log.
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'DIMOB - Incorporação de Construção de Imóveis.'
                                  );
         --
         vn_fase := 6;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '52' ); -- DIMOB
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         for rec in c_constr (vn_multorg_id) loop
            exit when c_constr%notfound or (c_constr%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            select   SUBSTR(vd_dt_ult_fecha, '7')
             into vd_dt_ult_fecha2
            from dual;
            --
            if vd_dt_ult_fecha2 is null or
               rec.dt_ref > vd_dt_ult_fecha2 then
               --
               delete from r_loteintws_fic where fichaincorpconstr_id = rec.id;
               --
               vn_fase := 7;
               --
               delete from ficha_incorp_constr where id = rec.id;
               --
               commit;
               --
            else
               --
               vn_fase := 7.1;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração do DIMOB não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'FICHA_INCORP_CONSTR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
      end if;
      --
      commit;
      --
      -- Garante que apenas o tipo de objeto em questão seja deprocessado.
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   elsif gv_cd_tipo_obj_integr = '3' then
      --
      -- Ficha de intermediário da venda de imoveis.
      --
      if nvl(vn_multorg_id,0) > 0
         or nvl(en_empresa_id,0) > 0 then
         --
         -- Registra log.
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'DIMOB - Ficha de Intermediário da Venda de Imóveis.'
                                  );
         --
         vn_fase := 8;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '52' ); -- DIMOB
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         for rec in c_venda (vn_multorg_id) loop
            exit when c_venda%notfound or (c_venda%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            select   SUBSTR(vd_dt_ult_fecha, '7')
             into vd_dt_ult_fecha2
            from dual;
            --
            if vd_dt_ult_fecha2 is null or
               rec.dt_ref > vd_dt_ult_fecha2 then
               --
               delete from r_loteintws_fiv where fichaintermvenda_id = rec.id;
               --
               vn_fase := 9;
               --
               delete from ficha_interm_venda where id = rec.id;
               --
               commit;
               --
            else
               --
               vn_fase := 9.1;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração do DIMOB não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'FICHA_INTERM_VENDA'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
      end if;
      --
      commit;
      --
      -- Garante que apenas o tipo de objeto em questão seja desprocessado.
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   end if;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(vn_empresa_id,0) > 0 then
      --
      vn_fase := 10;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'DIMOB - Declaração de Informação sobre Atividade Imobiliária.'
                               );
      --
      vn_fase := 11;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '52' ); -- DIMOB
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 12;
      --
      for rec in c_loc (vn_multorg_id) loop
         exit when c_loc%notfound or (c_loc%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         end if;
         --
          select   SUBSTR(vd_dt_ult_fecha, '7')
            into vd_dt_ult_fecha2
          from dual;
         --
         if vd_dt_ult_fecha2 is null or
            rec.dt_ref > vd_dt_ult_fecha2 then
            --
            delete from det_valor_locacao
             where locacao_id = rec.id;
            --
            vn_fase := 13;
            --
            delete from r_loteintws_locacao where locacao_id = rec.id;
            --
            vn_fase := 14;
            --
            delete from locacao where id = rec.id;
            --
            commit;
            --
         else
            --
            vn_fase := 15;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do DIMOB não permitido devido a data de '||
                                                                    'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'LOCACAO'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 16;
      --
      for rec in c_constr (vn_multorg_id) loop
         exit when c_constr%notfound or (c_constr%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         end if;
         --
         select   SUBSTR(vd_dt_ult_fecha, '7')
           into vd_dt_ult_fecha2
         from dual;
         --
         if vd_dt_ult_fecha2 is null or
            rec.dt_ref > vd_dt_ult_fecha2 then
            --
            delete from r_loteintws_fic where fichaincorpconstr_id = rec.id;
            --
            vn_fase := 17;
            --
            delete from ficha_incorp_constr where id = rec.id;
            --
            commit;
            --
         else
            --
            vn_fase := 17.1;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do DIMOB não permitido devido a data de '||
                                                                    'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'FICHA_INCORP_CONSTR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 18;
      --
      for rec in c_venda (vn_multorg_id) loop
         exit when c_venda%notfound or (c_venda%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         end if;
         --
         select   SUBSTR(vd_dt_ult_fecha, '7')
            into vd_dt_ult_fecha2
         from dual;
         --
         if vd_dt_ult_fecha2 is null or
            rec.dt_ref > vd_dt_ult_fecha2 then
            --
            delete from r_loteintws_fiv where fichaintermvenda_id = rec.id;
            --
            vn_fase := 19;
            --
            delete from ficha_interm_venda where id = rec.id;
            --
            commit;
            --
         else
            --
            vn_fase := 19.1;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do DIMOB não permitido devido a data de '||
                                                                    'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'FICHA_INTERM_VENDA'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 20;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o DIMOB (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_dimob): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_dimob fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_dimob;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar o Bloco I
------------------------------------------------------------------------------------------
procedure pkb_despr_ibipc ( en_empresa_id in empresa.id%type
                          , en_usuario_id in neo_usuario.id%type
                          , ed_dt_ini     in date
                          , ed_dt_fin     in date
                          )
is
   --
   vt_log_generico        dbms_sql.number_table;
   vn_fase                number := null;
   vn_multorg_id          mult_org.id%type;
   vn_loggenerico_id      log_generico.id%type;
   vn_objintegr_id        obj_integr.id%type;
   vd_dt_ult_fecha        fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_id                  inf_bloco_i_pc.id%type;
   --
   cursor c_ibipc (en_multorg_id mult_org.id%type) is
   select i.id
        , i.empresa_id
        , to_date(i.dm_mes_ref||'-'||i.ano_ref, 'mm/yyyy') dt_ref
     from inf_bloco_i_pc i
        , empresa e
        , usuario_empresa ue
    where to_date(i.dm_mes_ref||'-'||i.ano_ref,'mm/yyyy') between ed_dt_ini and ed_dt_fin
      and i.empresa_id      = nvl(en_empresa_id, i.empresa_id)
      and e.id = i.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Informações do Bloco I - EFD Contribuições.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '51' ); -- IBIPC - INF_BLOCO_I_PC
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase :=3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      for rec in c_ibipc (vn_multorg_id) loop
         exit when c_ibipc%notfound or (c_ibipc%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
         end if;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_ref > vd_dt_ult_fecha then
            --
            vn_fase := 5;
            --
            vt_log_generico.delete;
            --
            vn_fase := 6;
            --
            vn_id := rec.id;
            --
            pk_csf_api_bloco_i_pc.pkb_excluir_ibipc ( est_log_generico_ibipc  => vt_log_generico
                                                     , en_infblocoipc_id       => rec.id
                                                     );
            --
            vn_fase := 7;
            --
            delete from r_loteintws_ibipc where infblocoipc_id = rec.id;
            --
            delete from inf_bloco_i_pc where id = rec.id;
            --
         else
            --
            vn_fase := 9;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do IBIPC não permitido devido a data de '||
                                                                    'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'INF_BLOCO_I_PC'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 10;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o IBIPC (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_ibipc): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_ibipc fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_ibipc;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar CIAP
------------------------------------------------------------------------------------------
procedure pkb_despr_ciap ( en_empresa_id in empresa.id%Type
                         , en_usuario_id in neo_usuario.id%type
                         , ed_dt_ini     in date
                         , ed_dt_fin     in date
                         )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_id              icms_atperm_ciap.id%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_ciap (en_multorg_id mult_org.id%type) is
   select i.id
        , i.empresa_id
        , i.dt_ini
     from icms_atperm_ciap i
        , empresa e
        , usuario_empresa ue
    where (trunc(i.dt_ini) >= trunc(ed_dt_ini) and trunc(i.dt_fin) <= trunc(ed_dt_fin))
      and i.empresa_id      = nvl(en_empresa_id, i.empresa_id)
      and e.id = i.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'CIAP - Controle de Crédito de ICMS de Ativo Permanente.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '8' ); -- CIAP
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      for rec in c_ciap (vn_multorg_id) loop
         exit when c_ciap%notfound or (c_ciap%notfound) is null;
         --
         vn_fase := 4.1;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_ini > vd_dt_ult_fecha then
            --
            vn_fase := 6;
            --
            vt_log_generico.delete;
            --
            vn_fase := 7;
            --
            vn_id := rec.id;
            --
            pk_csf_api_ciap.pkb_excluir_ciap ( est_log_generico_ciap => vt_log_generico
                                             , en_icmsatpermciap_id  => rec.id );
            --
            vn_fase := 7.1;
            --
            delete from r_loteintws_ciap where icmsatpermciap_id = rec.id;
            --
            vn_fase := 8;
            --
            delete from icms_atperm_ciap where id = rec.id;
            --
         else
            --
            vn_fase := 9;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do CIAP não permitido devido a data de '||
                                                                    'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 10;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o ICMS de ativo permanente - CIAP (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_ciap): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_ciap fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_ciap;
------------------------------------------------------------------------------------------
-- Procedimento de desprocessamento do Bloco F
------------------------------------------------------------------------------------------
procedure pkb_despr_ddo ( en_empresa_id in empresa.id%type
                        , en_usuario_id in neo_usuario.id%type
                        , ed_dt_ini     in date
                        , ed_dt_fin     in date
                        )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   vn_empresa_id      number;
   --
begin
   --
   vn_fase := 1;
   --
   gn_empresa_id := en_empresa_id;
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '50' );
   --
   vn_fase := 2;
   --
   if gv_cd_tipo_obj_integr = '1' then
      --
      vn_fase := 3;
      -- Demais Doc. e Oper. Geradoras de Contribuições e Créditos - F100
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 3.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Demais Documentos e Operações - Bloco F - EFD Contribuições.'
                                  );
         --
         vn_fase := 3.2;
         --
         begin
            --
            delete from r_loteintws_demdocopcc rl
             where rl.demdocopergercc_id in ( select id
                                             from dem_doc_oper_ger_cc dd
                                            where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
                                              and dd.dt_oper between ed_dt_ini and ed_dt_fin
                                              and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1))
                                              and not exists ( select 1
                                                                 from ddof100_nfnd nd
                                                                where nd.demdocopergercc_id = dd.id ));
            --
            vn_fase := 3.3;
            --
            delete from log_dem_doc_oper_ger_cc ld
             where ld.demdocopergercc_id in ( select id
                                             from dem_doc_oper_ger_cc dd
                                            where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
                                              and dd.dt_oper between ed_dt_ini and ed_dt_fin
                                              and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1))
                                              and not exists ( select 1
                                                                 from ddof100_nfnd nd
                                                                where nd.demdocopergercc_id = dd.id ));
            --
            vn_fase := 3.4;
            --
            delete from pr_dem_doc_oper_ger_cc
             where demdocopergercc_id in ( select id
                                             from dem_doc_oper_ger_cc dd
                                            where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
                                              and dd.dt_oper between ed_dt_ini and ed_dt_fin
                                              and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1))
                                              and not exists ( select 1
                                                                 from ddof100_nfnd nd
                                                                where nd.demdocopergercc_id = dd.id ));
            --
            vn_fase := 3.5;
            --
            delete from dem_doc_oper_ger_cc dd
             where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
               and dd.dt_oper between ed_dt_ini and ed_dt_fin
               and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                , vn_objintegr_id ) -- en_objintegr_id
                                                                                , (ed_dt_ini - 1))
               and not exists ( select 1
                                  from ddof100_nfnd nd
                                 where nd.demdocopergercc_id = dd.id );
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - dem_doc_oper_ger_cc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 3.6;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '2' then
      --
      vn_fase := 4;
      -- Bens Incorp.At.Imob.-Oper.Gerad.Créd.base Enc.Depr./Amort. - F120/F130
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 4.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Bens Incorp.At.Imob.-Oper.Gerad.Créd.base Enc.Depr./Amort.'
                                  );
         --
         vn_fase := 4.2;
         --
         begin
            --
            delete from r_loteintws_bematmobpc
              where bemativimobopercredpc_id in (select id
                                                   from bem_ativ_imob_oper_cred_pc ba
                                                  where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
                                                    and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                    and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                   , (ed_dt_ini - 1)));
            --
            vn_fase := 4.3;
            --
            delete from pr_bai_oper_cred_pc
              where bemativimobopercredpc_id in (select id
                                                   from bem_ativ_imob_oper_cred_pc ba
                                                  where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
                                                    and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                    and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                   , (ed_dt_ini - 1)));
            --
            vn_fase := 4.4;
            --
            delete from bem_ativ_imob_oper_cred_pc ba
             where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
               and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
               and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                              , vn_objintegr_id ) -- en_objintegr_id
                                                                                                              , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - bem_ativ_imob_oper_cred_pc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 4.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   /* Utilizar somente o gv_cd_tipo_obj_integr = '2'
   elsif gv_cd_tipo_obj_integr = '3' then
      --
      vn_fase := 5;
      -- Bens Incorp.At.Imob.-Oper.Gerad.Créd.base no Valor de Aquis.
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 5.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Bens Incorp.At.Imob.-Oper.Gerad.Créd.base no Valor de Aquis.'
                                  );
         --
         vn_fase := 5.2;
         --
         begin
            --
            delete from r_loteintws_bematmobpc
              where bemativimobopercredpc_id in (select id
                                                   from bem_ativ_imob_oper_cred_pc ba
                                                  where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
                                                    and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                    and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                   , (ed_dt_ini - 1))
                                                    and ba.dm_tipo_oper = 1);
            --
            vn_fase := 5.3;
            --
            delete from pr_bai_oper_cred_pc
              where bemativimobopercredpc_id in (select id
                                                   from bem_ativ_imob_oper_cred_pc ba
                                                  where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
                                                    and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                    and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                   , (ed_dt_ini - 1))
                                                    and ba.dm_tipo_oper = 1);
            --
            vn_fase := 5.4;
            --
            delete from bem_ativ_imob_oper_cred_pc ba
             where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
               and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
               and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                              , vn_objintegr_id ) -- en_objintegr_id
                                                                                                              , (ed_dt_ini - 1))
               and ba.dm_tipo_oper = 1;
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - bem_ativ_imob_oper_cred_pc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 5.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   */
   elsif gv_cd_tipo_obj_integr = '4' then
      --
      vn_fase := 6;
      -- Crédito Presumido sobre Estoque de Abertura - F150
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 6.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Crédito Presumido sobre Estoque de Abertura.'
                                  );
         --
         vn_fase := 6.2;
         --
         begin
            --
            delete from r_loteintws_cpeabertpc rl
             where rl.credpresestabertpc_id in (select cp.id
                                                  from cred_pres_est_abert_pc cp
                                                 where cp.empresa_id = nvl(en_empresa_id,cp.empresa_id)
                                                   and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                   and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cp.empresa_id -- en_empresa_id
                                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                   , (ed_dt_ini - 1)));
            --
            vn_fase := 6.3;
            --
            delete from cred_pres_est_abert_pc cp
             where cp.empresa_id = nvl(en_empresa_id,cp.empresa_id)
               and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
               and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cp.empresa_id -- en_empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cred_pres_est_abert_pc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 6.4;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '5' then
      --
      vn_fase := 7;
      -- Operações da Ativ. Imobiliária - Unidade Imobiliária Vendida - F200
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 7.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Operações da Ativ. Imobiliária - Unidade Imobiliária Vendida.'
                                  );
         --
         vn_fase := 7.2;
         --
         begin
            --
            delete from r_loteintws_oaimobvend rl
             where rl.operativimobvend_id in ( select id
                                                  from oper_ativ_imob_vend oa
                                                 where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                   and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                   and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                              , vn_objintegr_id ) -- en_objintegr_id
                                                                                                              , (ed_dt_ini - 1)));
            --
            vn_fase := 7.3;
            --
            delete from oper_ativ_imob_proc_ref oai
             where oai.operativimobvend_id in ( select id
                                                  from oper_ativ_imob_vend oa
                                                 where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                   and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                   and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                              , vn_objintegr_id ) -- en_objintegr_id
                                                                                                              , (ed_dt_ini - 1)));
            --
            vn_fase := 7.4;
            --
            delete from oper_ativ_imob_cus_orc oai
             where oai.operativimobvend_id in ( select id
                                                  from oper_ativ_imob_vend oa
                                                 where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                   and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                   and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                              , vn_objintegr_id ) -- en_objintegr_id
                                                                                                              , (ed_dt_ini - 1)));
            --
            vn_fase := 7.5;
            --
            delete from oper_ativ_imob_cus_inc oai
             where oai.operativimobvend_id in ( select id
                                                  from oper_ativ_imob_vend oa
                                                 where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                   and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                   and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                              , vn_objintegr_id ) -- en_objintegr_id
                                                                                                              , (ed_dt_ini - 1)));
            --
            vn_fase := 7.6;
            --
            delete from oper_ativ_imob_vend oa
             where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
               and oa.dt_oper between ed_dt_ini and ed_dt_fin
               and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                                                        , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - oper_ativ_imob_vend - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 7.7;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '6' then
      --
      vn_fase := 8;
      -- CONS.OP.PJ RG.TRIB.LUCRO PRES. INC. PIS/PASEP COF.REG.CX. - F500
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 8.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - CONS.OP.PJ RG.TRIB.LUCRO PRES. INC. PIS/PASEP COF.REG.CX.'
                                  );
         --
         vn_fase := 8.2;
         --
         begin
            --
            delete from r_loteintws_coipcrc rl
             where rl.consoperinspcrc_id in ( select id
                                                from cons_oper_ins_pc_rc co
                                               where co.empresa_id = nvl(en_empresa_id,co.empresa_id)
                                                 and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                 and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
            --
            vn_fase := 8.3;
            --
            delete from pr_cons_oper_ins_pc_rc pc
             where pc.consoperinspcrc_id in ( select id
                                                from cons_oper_ins_pc_rc co
                                               where co.empresa_id = nvl(en_empresa_id,co.empresa_id)
                                                 and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                 and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
            --
            vn_fase := 8.4;
            --
            delete from cons_oper_ins_pc_rc co
             where co.empresa_id = nvl(en_empresa_id,co.empresa_id)
               and co.dt_ref between ed_dt_ini and ed_dt_fin
               and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_oper_ins_pc_rc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 8.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '7' then
      --
      vn_fase := 9;
      -- CONS.OP.PJ RG.TRIB.LUCRO PRES.-REG.CX.(AP.CONTR.UN.MED.PR.) - F510
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 9.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Cons.Op.PJ Rg.Trib.Lucro Pres.-Reg.Cx.(Ap.Contr.Un.Med.Pr.).'
                                  );
         --
         vn_fase := 9.2;
         --
         begin
            --
            delete from r_loteintws_coipcrcaum rl
             where rl.consoperinspcrcaum_id in (select id
                                                  from cons_oper_ins_pc_rc_aum co
                                                 where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                   and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                   and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
            --
            vn_fase := 9.3;
            --
            delete from pr_cons_op_ins_pcrc_aum pc
             where pc.consoperinspcrcaum_id in (select id
                                                  from cons_oper_ins_pc_rc_aum co
                                                 where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                   and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                   and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
            --
            vn_fase := 9.4;
            --
            delete from cons_oper_ins_pc_rc_aum co
             where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
               and co.dt_ref between ed_dt_ini and ed_dt_fin
               and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                                                      , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_oper_ins_pc_rc_aum - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 9.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '8' then
      --
      vn_fase := 10;
      -- Comp.Rec.Escrit.no Per.- Det.da Rec.Recebida pelo Reg.de cx. - F525
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 10.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Comp.Rec.Escrit.no Per.- Det.da Rec.Recebida pelo Reg.de cx.'
                                  );
         --
         vn_fase := 10.2;
         --
         begin
            --
            delete from r_loteintws_crdrc rl
             where rl.comprecdetrc_id in (select rc.id
                                            from comp_rec_det_rc rc
                                           where rc.empresa_id in nvl(en_empresa_id,rc.empresa_id)
                                             and rc.dt_ref between ed_dt_ini and ed_dt_fin
                                             and rc.dt_ref > nvl( pk_csf.fkg_recup_dtult_fecha_empresa( rc.empresa_id -- en_empresa_id
                                                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                                                                                      , (ed_dt_ini - 1)));
            --
            vn_fase := 10.3;
            --
            delete from comp_rec_det_rc rc
             where rc.empresa_id in nvl(en_empresa_id,rc.empresa_id)
               and rc.dt_ref between ed_dt_ini and ed_dt_fin
               and rc.dt_ref > nvl( pk_csf.fkg_recup_dtult_fecha_empresa( rc.empresa_id -- en_empresa_id
                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                                                        , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - comp_rec_det_rc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 10.4;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '9' then
      --
      vn_fase := 11;
      -- CONS.OP.PJ RG.TRIB.LUCRO PRES.- INC.PIS/COF. REG COMPET. - F550
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 11.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Cons.Op.PJ Rg.Trib.Lucro Pres.- Inc.PIS/COFINS Regime Competência.'
                                  );
         --
         vn_fase := 11.2;
         --
         begin
            --
            delete from r_loteintws_coircomp rl
             where rl.consoperinspcrcomp_id in ( select co.id
                                                   from cons_oper_ins_pc_rcomp co
                                                  where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                    and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                    and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                            , vn_objintegr_id ) -- en_objintegr_id
                                                                                                            , (ed_dt_ini - 1)));
            --
            vn_fase := 11.3;
            --
            delete from pr_cons_op_ins_pc_rcomp pc
             where pc.consoperinspcrcomp_id in ( select co.id
                                                   from cons_oper_ins_pc_rcomp co
                                                  where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                    and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                    and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                            , vn_objintegr_id ) -- en_objintegr_id
                                                                                                            , (ed_dt_ini - 1)));
            --
            vn_fase := 11.4;
            --
            delete from cons_oper_ins_pc_rcomp co
             where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
               and co.dt_ref between ed_dt_ini and ed_dt_fin
               and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_oper_ins_pc_rcomp - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 11.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '10' then
      --
      vn_fase := 12;
      -- CONS.OP.PJ RG.TRIB.LUCRO PRES.-PIS/COF.REG.COMP-AP.UN.MED.PR - F560
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 12.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Cons.Op.PJ Rg.Trib.Lucro Pres.-PIS/COFINS Reg.Comp-Ap.Un.Med.Prod.'
                                  );
         --
         vn_fase := 12.2;
         --
         begin
            --
            delete from r_loteintws_coircompaum rl
             where rl.consopinspcrcompaum_id in ( select id
                                                    from cons_op_ins_pcrcomp_aum co
                                                   where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                     and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                     and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                             , vn_objintegr_id ) -- en_objintegr_id
                                                                                                             , (ed_dt_ini - 1)));
            --
            vn_fase := 12.3;
            --
            delete from pr_cons_op_ins_pcrcoaum pc
             where pc.consopinspcrcompaum_id in ( select id
                                                    from cons_op_ins_pcrcomp_aum co
                                                   where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                     and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                     and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                             , vn_objintegr_id ) -- en_objintegr_id
                                                                                                             , (ed_dt_ini - 1)));
            --
            vn_fase := 12.4;
            --
            delete from cons_op_ins_pcrcomp_aum co
             where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
               and co.dt_ref between ed_dt_ini and ed_dt_fin
               and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_op_ins_pcrcomp_aum - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 12.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '11' then
      --
      vn_fase := 13;
      -- Contribuição Retida na Fonte - F600
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 13.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Contribuição Retida na Fonte.'
                                  );
         --
         vn_fase := 13.2;
         --
         begin
            --
            delete from r_loteintws_crfpc rl
             where rl.contrretfontepc_id in (select cr.id
                                               from contr_ret_fonte_pc cr
                                              where cr.empresa_id in nvl(en_empresa_id,cr.empresa_id)
                                                and cr.dt_ret between ed_dt_ini and ed_dt_fin
                                                and cr.dt_ret > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cr.empresa_id -- en_empresa_id
                                                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                                                                                        , (ed_dt_ini - 1))
                                                and not exists ( select 1 from contrretfonte_impretrec_pc c where c.contrretfontepc_id = cr.id ));
            --
            vn_fase := 13.3;
            --
            delete from contr_ret_fonte_pc cr
             where cr.empresa_id in nvl(en_empresa_id,cr.empresa_id)
               and cr.dt_ret between ed_dt_ini and ed_dt_fin
               and cr.dt_ret > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cr.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1))
               and not exists ( select 1 from contrretfonte_impretrec_pc c where c.contrretfontepc_id = cr.id );
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - contr_ret_fonte_pc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 13.4;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '12' then
      --
      vn_fase := 14;
      -- Deduções Diversas - F700
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 14.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Deduções Diversas.'
                                  );
         --
         vn_fase := 14.2;
         --
         begin
            --
            delete from r_loteintws_deddpc rl
             where rl.deducaodiversapc_id in ( select id
                                                 from deducao_diversa_pc dd
                                                where dd.empresa_id in nvl(en_empresa_id,dd.empresa_id)
                                                  and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                  and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                  , (ed_dt_ini - 1))); -- "Sim"
            --
            vn_fase := 14.3;
            --
            delete from log_deducao_diversa_pc ld
             where ld.deducaodiversapc_id in ( select id
                                                 from deducao_diversa_pc dd
                                                where dd.empresa_id in nvl(en_empresa_id,dd.empresa_id)
                                                  and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                  and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                  , (ed_dt_ini - 1))); -- "Sim"
            --
            vn_fase := 14.4;
            --
            delete from deducao_diversa_pc dd
             where dd.empresa_id in nvl(en_empresa_id,dd.empresa_id)
               and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
               and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - deducao_diversa_pc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 14.5;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '13' then
      --
      vn_fase := 15;
      -- Créd. Decorrentes de Eventos de Incorporação, Fusão e Cisão - F800
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         vn_fase := 15.1;
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Bloco F EFD - Créd. Decorrentes de Eventos de Incorporação, Fusão e Cisão.'
                                  );
         --
         vn_fase := 15.2;
         --
         begin
            --
            delete from r_loteintws_cdepc rl
             where rl.creddecoreventopc_id in (select cd.id
                                                 from cred_decor_evento_pc cd
                                                where cd.empresa_id in nvl(en_empresa_id,cd.empresa_id)
                                                  and cd.dt_evento between ed_dt_ini and ed_dt_fin
                                                  and cd.dt_evento > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cd.empresa_id -- en_empresa_id
                                                                                                             , vn_objintegr_id ) -- en_objintegr_id
                                                                                                             , (ed_dt_ini - 1)));
            --
            vn_fase := 15.3;
            --
            delete from cred_decor_evento_pc cd
             where cd.empresa_id in nvl(en_empresa_id,cd.empresa_id)
               and cd.dt_evento between ed_dt_ini and ed_dt_fin
               and cd.dt_evento > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cd.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cred_decor_evento_pc - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         vn_fase := 15.4;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   end if;
   --
   vn_fase := 16;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(vn_empresa_id,0) > 0 then
      --
      vn_fase := 17;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Demais Documentos e Operações - Bloco F EFD Contribuições.'
                               );
      --
      vn_fase := 18;
      --
      begin
         -- Demais Doc. e Oper. Geradoras de Contribuições e Créditos - F100
         delete from r_loteintws_demdocopcc rl
          where rl.demdocopergercc_id in ( select id
                                          from dem_doc_oper_ger_cc dd
                                         where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
                                           and dd.dt_oper between ed_dt_ini and ed_dt_fin
                                           and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                            , vn_objintegr_id ) -- en_objintegr_id
                                                                                                            , (ed_dt_ini - 1))
                                           and not exists ( select 1
                                                              from ddof100_nfnd nd
                                                             where nd.demdocopergercc_id = dd.id ));
         --
         vn_fase := 18.1;
         --
         delete from log_dem_doc_oper_ger_cc ld
          where ld.demdocopergercc_id in ( select id
                                          from dem_doc_oper_ger_cc dd
                                         where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
                                           and dd.dt_oper between ed_dt_ini and ed_dt_fin
                                           and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                            , vn_objintegr_id ) -- en_objintegr_id
                                                                                                            , (ed_dt_ini - 1))
                                           and not exists ( select 1
                                                              from ddof100_nfnd nd
                                                             where nd.demdocopergercc_id = dd.id ));
         --
         vn_fase := 18.2;
         --
         delete from pr_dem_doc_oper_ger_cc
          where demdocopergercc_id in ( select id
                                          from dem_doc_oper_ger_cc dd
                                         where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
                                           and dd.dt_oper between ed_dt_ini and ed_dt_fin
                                           and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                            , vn_objintegr_id ) -- en_objintegr_id
                                                                                                            , (ed_dt_ini - 1))
                                           and not exists ( select 1
                                                              from ddof100_nfnd nd
                                                             where nd.demdocopergercc_id = dd.id ));
         --
         vn_fase := 18.3;
         --
         delete from dem_doc_oper_ger_cc dd
          where dd.empresa_id = nvl(en_empresa_id,dd.empresa_id)
            and dd.dt_oper    between ed_dt_ini and ed_dt_fin
            and dd.dt_oper         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                             , vn_objintegr_id ) -- en_objintegr_id
                                                                             , (ed_dt_ini - 1))
            and not exists ( select 1
                               from ddof100_nfnd nd
                              where nd.demdocopergercc_id = dd.id );
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - dem_doc_oper_ger_cc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 19;
      --
      begin
         -- Bens Incorp.At.Imob.-Oper.Gerad.Créd.base Enc.Depr./Amort. - F120/F130
         delete from r_loteintws_bematmobpc
           where bemativimobopercredpc_id in (select id
                                                from bem_ativ_imob_oper_cred_pc ba
                                               where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
                                                 and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                 and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                                                                , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                , (ed_dt_ini - 1)));
         --
         vn_fase := 19.1;
         --
         delete from pr_bai_oper_cred_pc
           where bemativimobopercredpc_id in (select id
                                                from bem_ativ_imob_oper_cred_pc ba
                                               where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
                                                 and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                 and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                                                                , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                , (ed_dt_ini - 1)));
         --
         vn_fase := 19.2;
         --
         delete from bem_ativ_imob_oper_cred_pc ba
          where ba.empresa_id = nvl(en_empresa_id,ba.empresa_id)
            and to_date(ba.mes_ref || '/' || ba.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
            and to_date(ba.mes_ref|| '/' ||ba.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ba.empresa_id -- en_empresa_id
                                                                                                           , vn_objintegr_id ) -- en_objintegr_id
                                                                                                           , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - bem_ativ_imob_oper_cred_pc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 20;
      --
      begin
         -- Crédito Presumido sobre Estoque de Abertura - F150
         delete from r_loteintws_cpeabertpc rl
          where rl.credpresestabertpc_id in (select cp.id
                                               from cred_pres_est_abert_pc cp
                                              where cp.empresa_id = nvl(en_empresa_id,cp.empresa_id)
                                                and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                                and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cp.empresa_id -- en_empresa_id
                                                                                                                                                , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                                , (ed_dt_ini - 1)));
         --
         vn_fase := 20.1;
         --
         delete from cred_pres_est_abert_pc cp
          where cp.empresa_id = nvl(en_empresa_id,cp.empresa_id)
            and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
            and to_date(cp.mes_ref|| '/' || cp.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cp.empresa_id -- en_empresa_id
                                                                                                           , vn_objintegr_id ) -- en_objintegr_id
                                                                                                           , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cred_pres_est_abert_pc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 21;
      --
      begin
         -- Operações da Ativ. Imobiliária - Unidade Imobiliária Vendida - F200
         delete from r_loteintws_oaimobvend rl
          where rl.operativimobvend_id in ( select id
                                               from oper_ativ_imob_vend oa
                                              where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
         --
         vn_fase := 21.1;
         --
         delete from oper_ativ_imob_proc_ref oai
          where oai.operativimobvend_id in ( select id
                                               from oper_ativ_imob_vend oa
                                              where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
         --
         vn_fase := 21.2;
         --
         delete from oper_ativ_imob_cus_orc oai
          where oai.operativimobvend_id in ( select id
                                               from oper_ativ_imob_vend oa
                                              where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                           , vn_objintegr_id ) -- en_objintegr_id
                                                                                                           , (ed_dt_ini - 1)));
         --
         vn_fase := 21.3;
         --
         delete from oper_ativ_imob_cus_inc oai
          where oai.operativimobvend_id in ( select id
                                               from oper_ativ_imob_vend oa
                                              where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
                                                and oa.dt_oper between ed_dt_ini and ed_dt_fin
                                                and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                                                           , vn_objintegr_id ) -- en_objintegr_id
                                                                                                           , (ed_dt_ini - 1)));
         --
         vn_fase := 21.4;
         --
         delete from oper_ativ_imob_vend oa
          where oa.empresa_id = nvl(en_empresa_id,oa.empresa_id)
            and oa.dt_oper between ed_dt_ini and ed_dt_fin
            and oa.dt_oper > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oa.empresa_id -- en_empresa_id
                                                                     , vn_objintegr_id ) -- en_objintegr_id
                                                                     , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - oper_ativ_imob_vend - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 22;
      --
      begin
         -- CONS.OP.PJ RG.TRIB.LUCRO PRES. INC. PIS/PASEP COF.REG.CX. - F500
         delete from r_loteintws_coipcrc rl
          where rl.consoperinspcrc_id in ( select id
                                             from cons_oper_ins_pc_rc co
                                            where co.empresa_id = nvl(en_empresa_id,co.empresa_id)
                                              and co.dt_ref between ed_dt_ini and ed_dt_fin
                                              and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                                                                                      , (ed_dt_ini - 1)));
         --
         vn_fase := 22.1;
         --
         delete from pr_cons_oper_ins_pc_rc pc
          where pc.consoperinspcrc_id in ( select id
                                             from cons_oper_ins_pc_rc co
                                            where co.empresa_id = nvl(en_empresa_id,co.empresa_id)
                                              and co.dt_ref between ed_dt_ini and ed_dt_fin
                                              and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                                                                                      , (ed_dt_ini - 1)));
         --
         vn_fase := 22.2;
         --
         delete from cons_oper_ins_pc_rc co
          where co.empresa_id = nvl(en_empresa_id,co.empresa_id)
            and co.dt_ref between ed_dt_ini and ed_dt_fin
            and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                    , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_oper_ins_pc_rc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 23;
      --
      begin
         -- CONS.OP.PJ RG.TRIB.LUCRO PRES.-REG.CX.(AP.CONTR.UN.MED.PR.) - F510
         delete from r_loteintws_coipcrcaum rl
          where rl.consoperinspcrcaum_id in (select id
                                               from cons_oper_ins_pc_rc_aum co
                                              where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                                                                                      , (ed_dt_ini - 1)));
         --
         vn_fase := 23.1;
         --
         delete from pr_cons_op_ins_pcrc_aum pc
          where pc.consoperinspcrcaum_id in (select id
                                               from cons_oper_ins_pc_rc_aum co
                                              where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                                                                                      , (ed_dt_ini - 1)));
         --
         vn_fase := 23.2;
         --
         delete from cons_oper_ins_pc_rc_aum co
          where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
            and co.dt_ref between ed_dt_ini and ed_dt_fin
            and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                   , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_oper_ins_pc_rc_aum - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 24;
      --
      begin
         -- Comp.Rec.Escrit.no Per.- Det.da Rec.Recebida pelo Reg.de cx. - F525
         delete from r_loteintws_crdrc rl
          where rl.comprecdetrc_id in (select rc.id
                                         from comp_rec_det_rc rc
                                        where rc.empresa_id in nvl(en_empresa_id,rc.empresa_id)
                                          and rc.dt_ref between ed_dt_ini and ed_dt_fin
                                          and rc.dt_ref > nvl( pk_csf.fkg_recup_dtult_fecha_empresa( rc.empresa_id -- en_empresa_id
                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                   , (ed_dt_ini - 1)));
         --
         vn_fase := 24.1;
         --
         delete from comp_rec_det_rc rc
          where rc.empresa_id in nvl(en_empresa_id,rc.empresa_id)
            and rc.dt_ref between ed_dt_ini and ed_dt_fin
            and rc.dt_ref > nvl( pk_csf.fkg_recup_dtult_fecha_empresa( rc.empresa_id -- en_empresa_id
                                                                     , vn_objintegr_id ) -- en_objintegr_id
                                                                     , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - comp_rec_det_rc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 25;
      --
      begin
         -- CONS.OP.PJ RG.TRIB.LUCRO PRES.- INC.PIS/COF. REG COMPET. - F550
         delete from r_loteintws_coircomp rl
          where rl.consoperinspcrcomp_id in ( select id
                                                from cons_oper_ins_pc_rcomp co
                                               where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                 and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                 and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
         --
         vn_fase := 25.1;
         --
         delete from pr_cons_op_ins_pc_rcomp pc
          where pc.consoperinspcrcomp_id in ( select id
                                                from cons_oper_ins_pc_rcomp co
                                               where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                 and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                 and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                                                                                         , (ed_dt_ini - 1)));
         --
         vn_fase := 25.2;
         --
         delete from cons_oper_ins_pc_rcomp co
          where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
            and co.dt_ref between ed_dt_ini and ed_dt_fin
            and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                    , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_oper_ins_pc_rcomp - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 26;
      --
      begin
         -- CONS.OP.PJ RG.TRIB.LUCRO PRES.-PIS/COF.REG.COMP-AP.UN.MED.PR - F560
         delete from r_loteintws_coircompaum rl
          where rl.consopinspcrcompaum_id in ( select id
                                                 from cons_op_ins_pcrcomp_aum co
                                                where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                  and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                  and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                                                          , (ed_dt_ini - 1)));
         --
         vn_fase := 26.1;
         --
         delete from pr_cons_op_ins_pcrcoaum pc
          where pc.consopinspcrcompaum_id in ( select id
                                                 from cons_op_ins_pcrcomp_aum co
                                                where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
                                                  and co.dt_ref between ed_dt_ini and ed_dt_fin
                                                  and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                                                          , (ed_dt_ini - 1)));
         --
         vn_fase := 26.2;
         --
         delete from cons_op_ins_pcrcomp_aum co
          where co.empresa_id in nvl(en_empresa_id,co.empresa_id)
            and co.dt_ref between ed_dt_ini and ed_dt_fin
            and co.dt_ref > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( co.empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                    , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cons_op_ins_pcrcomp_aum - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 27;
      --
      begin
         -- Contribuição Retida na Fonte - F600
         delete from r_loteintws_crfpc rl
          where rl.contrretfontepc_id in (select cr.id
                                            from contr_ret_fonte_pc cr
                                           where cr.empresa_id in nvl(en_empresa_id,cr.empresa_id)
                                             and cr.dt_ret between ed_dt_ini and ed_dt_fin
                                             and cr.dt_ret > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cr.empresa_id -- en_empresa_id
                                                                                                     , vn_objintegr_id ) -- en_objintegr_id
                                                                                                     , (ed_dt_ini - 1))
                                             and not exists ( select 1 from contrretfonte_impretrec_pc c where c.contrretfontepc_id = cr.id ));
         --
         vn_fase := 27.1;
         --
         delete from contr_ret_fonte_pc cr
          where cr.empresa_id in nvl(en_empresa_id,cr.empresa_id)
            and cr.dt_ret between ed_dt_ini and ed_dt_fin
            and cr.dt_ret > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cr.empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                    , (ed_dt_ini - 1))
            and not exists ( select 1 from contrretfonte_impretrec_pc c where c.contrretfontepc_id = cr.id );
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - contr_ret_fonte_pc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 28;
      --
      begin
         -- Deduções Diversas - F700
         delete from r_loteintws_deddpc rl
          where rl.deducaodiversapc_id in ( select id
                                              from deducao_diversa_pc dd
                                             where dd.empresa_id in nvl(en_empresa_id,dd.empresa_id)
                                               and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                               and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                               , (ed_dt_ini - 1))); -- "Sim"
         --
         vn_fase := 28.1;
         --
         delete from log_deducao_diversa_pc ld
          where ld.deducaodiversapc_id in ( select id
                                              from deducao_diversa_pc dd
                                             where dd.empresa_id in nvl(en_empresa_id,dd.empresa_id)
                                               and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
                                               and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                               , (ed_dt_ini - 1))); -- "Sim"
         --
         vn_fase := 28.2;
         --
         delete from deducao_diversa_pc dd
          where dd.empresa_id in nvl(en_empresa_id,dd.empresa_id)
            and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') between ed_dt_ini and ed_dt_fin
            and to_date(dd.mes_ref|| '/' || dd.ano_ref,'mm/rrrr') > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id -- en_empresa_id
                                                                                                            , vn_objintegr_id ) -- en_objintegr_id
                                                                                                            , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - deducao_diversa_pc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 29;
      --
      begin
         -- Créd. Decorrentes de Eventos de Incorporação, Fusão e Cisão - F800
         delete from r_loteintws_cdepc rl
          where rl.creddecoreventopc_id in (select cd.id
                                              from cred_decor_evento_pc cd
                                             where cd.empresa_id in nvl(en_empresa_id,cd.empresa_id)
                                               and cd.dt_evento between ed_dt_ini and ed_dt_fin
                                               and cd.dt_evento > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cd.empresa_id -- en_empresa_id
                                                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                                                          , (ed_dt_ini - 1)));
         --
         vn_fase := 29.1;
         --
         delete from cred_decor_evento_pc cd
          where cd.empresa_id in nvl(en_empresa_id,cd.empresa_id)
            and cd.dt_evento between ed_dt_ini and ed_dt_fin
            and cd.dt_evento > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( cd.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
         --
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ddo - cred_decor_evento_pc - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 30;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o processo de Bloco F. Verifique (pk_despr_integr.pkb_despr_ddo): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_ddo fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_ddo;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar ECREDAC
------------------------------------------------------------------------------------------
procedure pkb_despr_ecredac ( en_empresa_id in empresa.id%Type
                            , en_usuario_id in neo_usuario.id%type
                            , ed_dt_ini     in date
                            , ed_dt_fin     in date
                            )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   vv_texto             varchar2(100);
   vn_desprocessa_total number;
   --
begin
   --
   vn_fase := 1;
   --
   gn_empresa_id := en_empresa_id;
   --
   vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '9' ); -- Ecredac
   --
   vn_fase := 1.1;
   --
   if gv_cd_tipo_obj_integr = '1' then    --|Integração de ordem de produção|--
      --
      vn_desprocessa_total := 0;
      --
      vv_texto := 'ECREDAC - Integração de Ordem de Produção.';
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 1.2;
      --
      begin
         delete from prodop_movop pm
          where pm.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                             , prod_op po
                         where po.id         = pm.prodop_id
                           and oc.id         = po.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and pm.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prodop_movop - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 1.3;
      --
      begin
         delete from prod_op_detalhe pd
          where pd.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                             , prod_op po
                         where po.id         = pd.prodop_id
                           and oc.id         = po.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and pd.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prod_op_detalhe - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 1.4;
      --
      begin
         delete from prod_op po
          where po.dt between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                         where oc.id         = po.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and po.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prod_op - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 1.5;
      --
      begin
         delete from prod_op po
          where po.dt between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                         where oc.id         = po.opcab_id_dest
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and po.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prod_op - destino - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 1.6;
      --
      begin
         delete from movop_itemnf mi
          where mi.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab oc
                             , mov_op mo
                         where mo.id         = mi.movop_id
                           and oc.id         = mo.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and mi.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - movop_itemnf - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 1.7;
      --
      begin
         delete from mov_op mo
          where mo.dt between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab oc
                         where oc.id         = mo.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and mo.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - mov_op - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 1.8;
      --
      begin
         delete from op_cab oc
          where oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
            and oc.dt   between ed_dt_ini and ed_dt_fin
            and oc.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - op_cab - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      commit;
      --
   elsif gv_cd_tipo_obj_integr = '2' then --|Integraçãos de rateio direto de frete|--
      --
      vn_desprocessa_total := 0;
      --
      vv_texto := 'ECREDAC - Integraçãos de Rateio Direto de Frete.';
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 1.9;
      --
      begin
         delete from frete_itemnf fi
          where fi.dt_util between ed_dt_ini and ed_dt_fin
            and exists (select ct.empresa_id
                          from conhec_transp ct
                         where ct.id         = fi.conhectransp_id
                           and ct.empresa_id = nvl(en_empresa_id,ct.empresa_id)
                           and fi.dt_util    > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ct.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - frete_itemnf - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      commit;
      --
   elsif gv_cd_tipo_obj_integr = '3' then --|Integrações de movimentações de produto|--
      --
      vn_desprocessa_total := 0;
      --
      vv_texto := 'ECREDAC - Integrações de Movimentações de Produto.';
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 2;
      --
      begin
         delete from movto_estq me
          where me.empresa_id = nvl(en_empresa_id,me.empresa_id)
            and me.dt   between ed_dt_ini and ed_dt_fin
            and me.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( me.empresa_id -- en_empresa_id
                                                                     , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - movto_estq - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 2.1;
      --
      begin
         delete from mov_transf mt
          where mt.empresa_id = nvl(en_empresa_id,mt.empresa_id)
            and mt.dt   between ed_dt_ini and ed_dt_fin
            and mt.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( mt.empresa_id -- en_empresa_id
                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - mov_transf - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 2.2;
      --
      commit;
      --
   elsif gv_cd_tipo_obj_integr = '4' then --|Integrações de códigos de enquadramento legal|--
      --
      -- Objeto não exclui nenhum registro de nunhuma tabela.
      vn_desprocessa_total := 0;
      --
   elsif gv_cd_tipo_obj_integr = '5' then --|Itens de notas fiscais com código de enquadramento legal|--
      --
      vn_desprocessa_total := 0;
      --
      vv_texto := 'ECREDAC - Itens de Notas Fiscais com Código de Enquadramento Legal.';
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 2.3;
      --
      begin
         delete from itemnf_cod_legal ic
          where ic.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select nf.empresa_id
                          from nota_fiscal      nf
                             , item_nota_fiscal it
                         where it.id         = ic.itemnotafiscal_id
                           and nf.id         = it.notafiscal_id
                           and nf.empresa_id = nvl(en_empresa_id,nf.empresa_id)
                           and ic.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( nf.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - itemnf_cod_legal - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      commit;
      --
   elsif gv_cd_tipo_obj_integr = '6' then --|Itens de notas fiscais de entrada que não geram estoque|--
      --
      vn_desprocessa_total := 0;
      --
      vv_texto := 'ECREDAC - Itens de Notas Fiscais de Entrada que não geram Estoque.';
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 2.4;
      --
      begin
         delete from itemnf_nao_gera_est ig
          where ig.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select nf.empresa_id
                          from nota_fiscal nf
                         where nf.id         = ig.notafiscal_id
                           and nf.empresa_id = nvl(en_empresa_id,nf.empresa_id)
                           and ig.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( nf.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - itemnf_nao_gera_est - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      commit;
      --
   elsif gv_cd_tipo_obj_integr is null then --|Desprocessar o objeto inteiro|--
      --
      vn_desprocessa_total := -1;
      --
      vv_texto := 'ECREDAC.';
      --
   end if;
   --
   vn_fase := 3;
   --
   if vn_desprocessa_total = -1 then
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => vv_texto
                               );
      --
      vn_fase := 4;
      --
      --vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '9' ); -- Ecredac
      --
      --vn_fase := 3;
      --
      begin
         delete from movto_estq me
          where me.empresa_id = nvl(en_empresa_id,me.empresa_id)
            and me.dt   between ed_dt_ini and ed_dt_fin
            and me.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( me.empresa_id -- en_empresa_id
                                                                     , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - movto_estq - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 5;
      --
      begin
         delete from itemnf_nao_gera_est ig
          where ig.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select nf.empresa_id
                          from nota_fiscal nf
                         where nf.id         = ig.notafiscal_id
                           and nf.empresa_id = nvl(en_empresa_id,nf.empresa_id)
                           and ig.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( nf.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - itemnf_nao_gera_est - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 6;
      --
      begin
         delete from itemnf_cod_legal ic
          where ic.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select nf.empresa_id
                          from nota_fiscal      nf
                             , item_nota_fiscal it
                         where it.id         = ic.itemnotafiscal_id
                           and nf.id         = it.notafiscal_id
                           and nf.empresa_id = nvl(en_empresa_id,nf.empresa_id)
                           and ic.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( nf.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - itemnf_cod_legal - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 7;
      --
      begin
         delete from mov_transf mt
          where mt.empresa_id = nvl(en_empresa_id,mt.empresa_id)
            and mt.dt   between ed_dt_ini and ed_dt_fin
            and mt.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( mt.empresa_id -- en_empresa_id
                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - mov_transf - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 8;
      --
      begin
         delete from frete_itemnf fi
          where fi.dt_util between ed_dt_ini and ed_dt_fin
            and exists (select ct.empresa_id
                          from conhec_transp ct
                         where ct.id         = fi.conhectransp_id
                           and ct.empresa_id = nvl(en_empresa_id,ct.empresa_id)
                           and fi.dt_util    > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ct.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - frete_itemnf - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 9;
      --
      begin
         delete from prodop_movop pm
          where pm.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                             , prod_op po
                         where po.id         = pm.prodop_id
                           and oc.id         = po.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and pm.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prodop_movop - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 10;
      --
      begin
         delete from prod_op_detalhe pd
          where pd.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                             , prod_op po
                         where po.id         = pd.prodop_id
                           and oc.id         = po.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and pd.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prod_op_detalhe - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 11;
      --
      begin
         delete from prod_op po
          where po.dt between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                         where oc.id         = po.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and po.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prod_op - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 12;
      --
      begin
         delete from prod_op po
          where po.dt between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab  oc
                         where oc.id         = po.opcab_id_dest
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and po.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - prod_op - destino - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 13;
      --
      begin
         delete from movop_itemnf mi
          where mi.dt_refer between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab oc
                             , mov_op mo
                         where mo.id         = mi.movop_id
                           and oc.id         = mo.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and mi.dt_refer   > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - movop_itemnf - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 14;
      --
      begin
         delete from mov_op mo
          where mo.dt between ed_dt_ini and ed_dt_fin
            and exists (select oc.empresa_id
                          from op_cab oc
                         where oc.id         = mo.opcab_id
                           and oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
                           and mo.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                  , (ed_dt_ini - 1)));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - mov_op - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 15;
      --
      begin
         delete from op_cab oc
          where oc.empresa_id = nvl(en_empresa_id,oc.empresa_id)
            and oc.dt   between ed_dt_ini and ed_dt_fin
            and oc.dt         > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oc.empresa_id -- en_empresa_id
                                                                        , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
      exception
         when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - op_cab - fase ('||vn_fase||'): '||sqlerrm);
      end;
      --
      vn_fase := 16;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir o processo de ECREDAC. Verifique (pk_despr_integr.pkb_despr_ecredac): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_ecredac fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_ecredac;
-------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Dados Contábeis                                        --
-------------------------------------------------------------------------------------------
procedure pkb_despr_dados_contab ( en_empresa_id in empresa.id%Type
                                 , en_usuario_id in neo_usuario.id%type
                                 , ed_dt_ini     in date
                                 , ed_dt_fin     in date
                                 )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   vd_dt_ult_fecha    date;
   --
   vn_qtde_sped_ecd   number;
   vn_qtde_sped_ecf   number;
   --
   vn_empresa_id        number;
   --
   cursor c_idsp (en_multorg_id mult_org.id%type) is
      select idsp.id
           , idsp.empresa_id
           , idsp.dt_ini
           , idsp.dt_fim
        from int_det_saldo_periodo idsp
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and idsp.empresa_id = nvl(en_empresa_id, idsp.empresa_id)
         and e.id = idsp.empresa_id
         and idsp.dt_ini >= ed_dt_ini
         and idsp.dt_fim <= ed_dt_fin;
   --
   cursor c_ilc (en_multorg_id mult_org.id%type) is
      select ilc.id
           , ilc.empresa_id
           , ilc.dt_lcto dt_ini
        from int_lcto_contabil ilc
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and ilc.empresa_id = nvl(en_empresa_id, ilc.empresa_id)
         and e.id = ilc.empresa_id
         and ilc.dt_lcto between ed_dt_ini and ed_dt_fin;
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr = '1' then --|Detalhamento do saldo por periodo|--
      --
      if nvl(vn_multorg_id,0) > 0
         or nvl(vn_empresa_id,0) > 0 then
         --
         vn_fase := 1;
         -- registra o log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Dados Contábeis - Detalhamento do Saldo por Período.'
                                  );
         --
         vn_fase := 2;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '32' ); -- Dados Contábeis
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         vn_fase := 3;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         vn_fase := 3.1;
         -- Verifica se existe Sped Contabil no intervalo
         begin
            --
            select count(1)
              into vn_qtde_sped_ecd
              from abertura_ecd
             where empresa_id = en_empresa_id
               and dm_situacao <> 0 -- Aberto
               and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
                     and to_number(to_char(dt_fim, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
                   );
            --
         exception
            when others then
               vn_qtde_sped_ecd := 0;
         end;
         --
         vn_fase := 3.2;
         --
         if nvl(vn_qtde_sped_ecd,0) > 0 then
            --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Existe Sped Contábil para o período informado (Data ' || to_char(ed_dt_ini, 'DD/MM/RRRR') || ' até ' || to_char(ed_dt_fin, 'DD/MM/RRRR') || ').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => 1
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
         vn_fase := 3.3;
         -- Verifica se existe Sped ECF no intervalo
         begin
            --
            select count(1)
              into vn_qtde_sped_ecf
              from abertura_ecf
             where empresa_id = en_empresa_id
               and dm_situacao <> 0 -- Aberto
               and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
                     and to_number(to_char(dt_fin, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
                   );
            --
         exception
            when others then
               vn_qtde_sped_ecf := 0;
         end;
         --
         vn_fase := 3.4;
         --
         if nvl(vn_qtde_sped_ecf,0) > 0 then
            --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Existe Sped ECF para o período informado (Data ' || to_char(ed_dt_ini, 'DD/MM/RRRR') || ' até ' || to_char(ed_dt_fin, 'DD/MM/RRRR') || ').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => 1
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
         vn_fase := 4;
         --
         for rec in c_idsp (vn_multorg_id) loop
            exit when c_idsp%notfound or (c_idsp%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_ini > vd_dt_ult_fecha then
               --
               vn_fase := 5;
               --
               begin
                  --
                  delete from r_loteintws_idsp
                   where intdetsaldoperiodo_id = rec.id;
                  --
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - r_loteintws_idsp - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
               vn_fase := 6;
               --
               begin
                  --
                  delete from int_trans_saldo_cont_ant
                   where intdetsaldoperiodo_id = rec.id;
                  --
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - int_trans_saldo_cont_ant - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
               begin
                  delete from int_det_saldo_periodo idsp
                   where idsp.id = rec.id;
               exception
                  when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - int_det_saldo_periodo - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
            else
               --
               vn_fase := 6;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração de Dados Contábeis não '||
                                                                       'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
      end if;
      --
      commit;
      --
      -- Para desprocessar apenas o o tipo do objeto especifico
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   elsif gv_cd_tipo_obj_integr = '2' then --|Lançamentos Contabeis|--
      --
      if nvl(vn_multorg_id,0) > 0
         or nvl(vn_empresa_id,0) > 0 then
         --
         vn_fase := 7;
         -- registra o log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Dados Contábeis - Lançamentos Contábeis.'
                                  );
         --
         vn_fase := 8;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '32' ); -- Dados Contábeis
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         vn_fase := 9;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         vn_fase := 10;
         -- Verifica se existe Sped Contabil no intervalo
         begin
            --
            select count(1)
              into vn_qtde_sped_ecd
              from abertura_ecd
             where empresa_id = en_empresa_id
               and dm_situacao <> 0 -- Aberto
               and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
                     and to_number(to_char(dt_fim, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
                   );
            --
         exception
            when others then
               vn_qtde_sped_ecd := 0;
         end;
         --
         vn_fase := 10.1;
         --
         if nvl(vn_qtde_sped_ecd,0) > 0 then
            --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Existe Sped Contábil para o período informado (Data ' || to_char(ed_dt_ini, 'DD/MM/RRRR') || ' até ' || to_char(ed_dt_fin, 'DD/MM/RRRR') || ').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => 1
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
         vn_fase := 10.2;
         -- Verifica se existe Sped ECF no intervalo
         begin
            --
            select count(1)
              into vn_qtde_sped_ecf
              from abertura_ecf
             where empresa_id = en_empresa_id
               and dm_situacao <> 0 -- Aberto
               and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
                     and to_number(to_char(dt_fin, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
                   );
            --
         exception
            when others then
               vn_qtde_sped_ecf := 0;
         end;
         --
         vn_fase := 10.3;
         --
         if nvl(vn_qtde_sped_ecf,0) > 0 then
            --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Existe Sped ECF para o período informado (Data ' || to_char(ed_dt_ini, 'DD/MM/RRRR') || ' até ' || to_char(ed_dt_fin, 'DD/MM/RRRR') || ').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => 1
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
         vn_fase := 11;
         --
         for rec in c_ilc (vn_multorg_id) loop
            exit when c_ilc%notfound or (c_ilc%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_ini > vd_dt_ult_fecha then
               --
               vn_fase := 12;
               --
               begin
                  delete from int_partida_lcto ic
                   where ic.intlctocontabil_id = rec.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - int_partida_lcto - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
               vn_fase := 13;
               --
               begin
                  delete from log_int_lcto_contabil li
                   where li.intlctocontabil_id = rec.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - log_int_lcto_contabil - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
               vn_fase := 14;
               --
               delete from r_loteintws_ilc
                where intlctocontabil_id = rec.id;
               --
               begin
                  delete from int_lcto_contabil il
                   where il.id = rec.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - int_lcto_contabil - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
            else
               --
               vn_fase := 14;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração de Dados Contábeis não '||
                                                                       'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
      end if;
      --
      commit;
      -- Para desprocessar apenas o o tipo do objeto especifico
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   end if;
   --
   vn_fase := 1;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(vn_empresa_id,0) > 0 then
      --
      vn_fase := 15;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Dados Contábeis.'
                               );
      --
      vn_fase := 16;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '32' ); -- Dados Contábeis
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 17;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 17.2;
      -- Verifica se existe Sped Contabil no intervalo
      begin
         --
         select count(1)
           into vn_qtde_sped_ecd
           from abertura_ecd
          where empresa_id = en_empresa_id
            and dm_situacao <> 0 -- Aberto
            and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
                  and to_number(to_char(dt_fim, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
                );
         --
      exception
         when others then
            vn_qtde_sped_ecd := 0;
      end;
      --
      vn_fase := 17.3;
      --
      if nvl(vn_qtde_sped_ecd,0) > 0 then
         --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Existe Sped Contábil para o período informado (Data ' || to_char(ed_dt_ini, 'DD/MM/RRRR') || ' até ' || to_char(ed_dt_fin, 'DD/MM/RRRR') || ').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => 1
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
         --
      end if;
      --
      vn_fase := 17.4;
      -- Verifica se existe Sped ECF no intervalo
      begin
         --
         select count(1)
           into vn_qtde_sped_ecf
           from abertura_ecf
          where empresa_id = en_empresa_id
            and dm_situacao <> 0 -- Aberto
            and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
                  and to_number(to_char(dt_fin, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
                );
         --
      exception
         when others then
            vn_qtde_sped_ecf := 0;
      end;
      --
      vn_fase := 17.5;
      --
      if nvl(vn_qtde_sped_ecf,0) > 0 then
         --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Existe Sped ECF para o período informado (Data ' || to_char(ed_dt_ini, 'DD/MM/RRRR') || ' até ' || to_char(ed_dt_fin, 'DD/MM/RRRR') || ').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => 1
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
         --
      end if;
      --
      vn_fase := 18;
      --
      for rec in c_idsp (vn_multorg_id) loop
         exit when c_idsp%notfound or (c_idsp%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_ini > vd_dt_ult_fecha then
            --
            vn_fase := 19;
            --
            begin
               --
               delete from r_loteintws_idsp
                where intdetsaldoperiodo_id = rec.id;
               --
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - r_loteintws_idsp - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 20;
            --
            begin
               --
               delete from int_trans_saldo_cont_ant
                where intdetsaldoperiodo_id = rec.id;
               --
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - int_trans_saldo_cont_ant - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            begin
               delete from int_det_saldo_periodo idsp
                where idsp.id = rec.id;
            exception
               when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - int_det_saldo_periodo - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 21;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Dados Contábeis não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      for rec in c_ilc (vn_multorg_id) loop
         exit when c_ilc%notfound or (c_ilc%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_ini > vd_dt_ult_fecha then
            --
            vn_fase := 22;
            --
            begin
               delete from int_partida_lcto ic
                where ic.intlctocontabil_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - int_partida_lcto - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 23;
            --
            begin
               delete from log_int_lcto_contabil li
                where li.intlctocontabil_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_ecredac - log_int_lcto_contabil - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 24;
            --
            delete from r_loteintws_ilc
             where intlctocontabil_id = rec.id;
            --
            begin
               delete from int_lcto_contabil il
                where il.id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_contab - int_lcto_contabil - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 25;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Dados Contábeis não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 26;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir os Dados Contábeis. Verifique (pk_despr_integr.pkb_despr_dados_contab): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_dados_contab fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_dados_contab;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Produção Diaria de Usina
------------------------------------------------------------------------------------------
procedure pkb_despr_pdu ( en_empresa_id in empresa.id%Type
                        , en_usuario_id in neo_usuario.id%type
                        , ed_dt_ini     in date
                        , ed_dt_fin     in date
                        )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_pdu (en_multorg_id mult_org.id%type) is
      select p.id
           , p.empresa_id
           , p.dt_prod
        from prod_dia_usina p
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and p.empresa_id = nvl(en_empresa_id, p.empresa_id)
         and e.id = p.empresa_id
         and (trunc(p.dt_prod) >= trunc(ed_dt_ini) and trunc(p.dt_prod) <= trunc(ed_dt_fin));
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Produção Diária de Usina.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '33' ); -- Produção Diária de Usina
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      for rec in c_pdu (vn_multorg_id) loop
         exit when c_pdu%notfound or (c_pdu%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         delete from r_loteintws_pdu
          where proddiausina_id = rec.id;
         --
         delete from prod_dia_usina p
          where p.id = rec.id
            and p.dt_prod > vd_dt_ult_fecha;
         --
      end loop;
      --
      vn_fase := 4;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a Produção diária. Verifique (pk_despr_integr.pkb_despr_pdu): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_pdu fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_pdu;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar MANAD
------------------------------------------------------------------------------------------
procedure pkb_despr_manad ( en_empresa_id in empresa.id%Type
                          , en_usuario_id in neo_usuario.id%type
                          , ed_dt_ini     in date
                          , ed_dt_fin     in date
                          )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   vn_empresa_id      number;
   --
   cursor c_ifp (en_multorg_id mult_org.id%type) is
      select ifp.id
           , ifp.mes
           , ifp.ano
           , ifp.empresa_id
        from inf_folha_pgto ifp
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and e.id = ifp.empresa_id
         and ifp.empresa_id = nvl(en_empresa_id, ifp.empresa_id)
         and to_date(ifp.mes||'/'||ifp.ano,'MM/RRRR') between trunc(ed_dt_ini,'MM') and trunc(ed_dt_fin,'MM');
   --
   cursor c_mestre (en_multorg_id mult_org.id%type) is
      select m.id id
           , m.dt_comp
           , m.empresa_id
        from mestre_folha_pgto m
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and e.id = m.empresa_id
         and m.empresa_id = nvl(en_empresa_id, m.empresa_id)
         and m.dt_comp between ed_dt_ini and ed_dt_fin;
   --
   cursor c_cont (en_multorg_id mult_org.id%type) is
      select c.id   id
           , c.dt_cont
           , l.empresa_id
        from cont_folha_pgto c
           , lotacao_folha l
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and e.id = l.empresa_id
         and l.empresa_id = nvl(en_empresa_id,l.empresa_id)
         and l.id            = c.lotacaofolha_id
         and c.dt_cont between ed_dt_ini and ed_dt_fin;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr in('1', '2', '3') then
      --
      -- Informação de cadastro de trabalhadores = 1.
      -- Informação da lotação da folha de pagamento = 2.
      -- Informações rubricas de folhas de pagamentos = 3.
      vn_multorg_id := -1;
      vn_empresa_id := -1;
      --
   elsif gv_cd_tipo_obj_integr = '4' then
      --
      -- Mestre da folha de pagamento.
      -- registra o log
      if nvl(vn_multorg_id,0) > 0
         or nvl(vn_empresa_id,0) > 0 then
         --
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'MANAD - Mestre da Folha de Pagamento.'
                                  );
         --
         vn_fase := 2;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '45' ); -- MANAD
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         vn_fase := 3;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         for rec in c_mestre (vn_multorg_id) loop
            exit when c_mestre%notfound or (c_mestre%notfound) is null;
            --
            vn_fase := 4;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            vn_fase := 5;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_comp > vd_dt_ult_fecha then
               --
               vn_fase := 6;
               --
               begin
                  delete from item_folha_pgto
                   where mestrefolhapgto_id = rec.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.PKB_DESPR_MANAD - item_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
               vn_fase := 7;
               --
               begin
                  --
                  delete from r_loteintws_mfp
                   where mestrefolhapgto_id = rec.id;
                  --
                  delete from mestre_folha_pgto
                   where id = rec.id;
                  --
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - mestre_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
            else
               --
               vn_fase := 8;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração do MANAD (item e mestre da folha) não '||
                                                                       'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
         vn_fase := 9;
         --
         commit;
         --
         -- Garante que desprocesse apenas o tipo de objeto em questão.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '5' then
      --
      -- Informações da folha de pagamento.
      -- Registra o log
      if nvl(vn_multorg_id,0) > 0
         or nvl(vn_empresa_id,0) > 0 then
         --
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'MANAD - Informações da Folha de Pagamento.'
                                  );
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '45' ); -- MANAD
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         vn_fase := 10;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         for rec in c_ifp (vn_multorg_id) loop
            exit when c_ifp%notfound or (c_ifp%notfound) is null;
            --
            vn_fase := 11;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            vn_fase := 12;
            --
            if vd_dt_ult_fecha is null or
               to_date(rec.mes||'/'||rec.ano,'MM/RRRR') > vd_dt_ult_fecha then
               --
               vn_fase := 13;
               --
               begin
                  --
                  delete from r_loteintws_ifp
                   where inffolhapgto_id = rec.id;
                  --
                  delete from inf_folha_pgto
                   where id = rec.id;
                  --
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - inf_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
               end;
               --
            else
               --
               vn_fase := 14;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração do MANAD (informações da folha de pagamento) não permitido '||
                                                                       'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
         vn_fase := 15;
         --
         commit;
         --
         -- Garante que desprocesse apenas o tipo de objeto em questão.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '6' then
      --
      -- Contabilização da folha de pagamento.
      -- Registrar log
      if nvl(vn_multorg_id,0) > 0
        or nvl(vn_empresa_id,0) > 0 then
        --
        pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                 , en_usuario_id => en_usuario_id
                                 , ed_dt_ini     => ed_dt_ini
                                 , ed_dt_fin     => ed_dt_fin
                                 , ev_texto      => 'MANAD - Contabilização da Folha de Pagamento.'
                                 );
        --
        vn_fase := 16;
        --
        if nvl(gn_objintegr_id,0) = 0 then
           vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '45' ); -- MANAD
        else
           vn_objintegr_id := gn_objintegr_id;
        end if;
        --
        vn_fase := 17;
        --
        if nvl(en_empresa_id,0) > 0 then
           --
           vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                      , vn_objintegr_id ) -- en_objintegr_id
                                , (ed_dt_ini - 1));
           --
           if nvl(vn_multorg_id,0) = 0 then
              --
              vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
              --
           end if;
           --
        end if;
        --
        for rec in c_cont (vn_multorg_id) loop
           exit when c_cont%notfound or (c_cont%notfound) is null;
           --
           vn_fase := 18;
           --
           if nvl(en_empresa_id,0) = 0 then
              --
              vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                         , vn_objintegr_id ) -- en_objintegr_id
                                   , (ed_dt_ini - 1));
              --
           end if;
           --
           vn_fase := 19;
           --
           if vd_dt_ult_fecha is null or
              rec.dt_cont > vd_dt_ult_fecha then
              --
              vn_fase := 20;
              --
              begin
                 --
                 delete from r_loteintws_cfp
                  where contfolhapgto_id = rec.id;
                 --
                 delete from cont_folha_pgto
                  where id = rec.id;
                 --
              exception
                 when others then
                    raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - cont_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
              end;
              --
           else
              --
              vn_fase := 21;
              -- Gerar log no agendamento devido a data de fechamento
              pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                               , ev_mensagem       => 'Desprocessar Integração'
                                               , ev_resumo         => 'Período informado para desprocessar a integração do MANAD (contábil da folha) não permitido '||
                                                                      'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                               , en_tipo_log       => info_fechamento
                                               , en_referencia_id  => null
                                               , ev_obj_referencia => 'DESPR_INTEGR'
                                               , en_empresa_id     => gn_empresa_id
                                               );
              --
           end if;
           --
        end loop;
        --
        vn_fase := 22;
        --
        commit;
        --
        -- Garante que desprocesse apenas o tipo de objeto em questão.
        vn_multorg_id := -1;
        vn_empresa_id := -1;
        --
      end if;
      --
   end if;
   --
   vn_fase := 23;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(vn_empresa_id,0) > 0 then
      --
      vn_fase := 24;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'MANAD.'
                               );
      --
      vn_fase := 25;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '45' ); -- MANAD
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 26;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 27;
      --
      for rec in c_ifp (vn_multorg_id) loop
         exit when c_ifp%notfound or (c_ifp%notfound) is null;
         --
         vn_fase := 28;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 29;
         --
         if vd_dt_ult_fecha is null or
            to_date(rec.mes||'/'||rec.ano,'MM/RRRR') > vd_dt_ult_fecha then
            --
            vn_fase := 30;
            --
            begin
               --
               delete from r_loteintws_ifp
                where inffolhapgto_id = rec.id;
               --
               delete from inf_folha_pgto
                where id = rec.id;
               --
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - inf_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 31;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do MANAD (informações da folha de pagamento) não permitido '||
                                                                    'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      for rec in c_mestre (vn_multorg_id) loop
         exit when c_mestre%notfound or (c_mestre%notfound) is null;
         --
         vn_fase := 32;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 33;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_comp > vd_dt_ult_fecha then
            --
            vn_fase := 34;
            --
            begin
               delete from item_folha_pgto
                where mestrefolhapgto_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - item_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 35;
            --
            begin
               --
               delete from r_loteintws_mfp
                where mestrefolhapgto_id = rec.id;
               --
               delete from mestre_folha_pgto
                where id = rec.id;
               --
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - mestre_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 36;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do MANAD (item e mestre da folha) não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 37;
      --
      for rec in c_cont (vn_multorg_id) loop
         exit when c_cont%notfound or (c_cont%notfound) is null;
         --
         vn_fase := 38;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 39;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_cont > vd_dt_ult_fecha then
            --
            vn_fase := 40;
            --
            begin
               --
               delete from r_loteintws_cfp
                where contfolhapgto_id = rec.id;
               --
               delete from cont_folha_pgto
                where id = rec.id;
               --
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_manad - cont_folha_pgto - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 41;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do MANAD (contábil da folha) não permitido '||
                                                                    'devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 42;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir dados da Folha de Pagamento - MANAD. Verifique (pk_despr_integr.pkb_despr_manad): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_manad fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_manad;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Informações de Valores Agregados
------------------------------------------------------------------------------------------
procedure pkb_despr_iva ( en_empresa_id in empresa.id%Type
                        , en_usuario_id in neo_usuario.id%type
                        , ed_dt_ini     in date
                        , ed_dt_fin     in date
                        )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_iva (en_multorg_id mult_org.id%type) is
      select iva.id
           , iva.empresa_id
           , iva.mes
           , iva.ano
        from inf_valor_agreg iva
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and iva.empresa_id = nvl(en_empresa_id, iva.empresa_id)
         and e.id = iva.empresa_id
         and to_date(iva.mes||'/'||iva.ano,'MM/RRRR') between trunc(ed_dt_ini,'MM') and trunc(ed_dt_fin,'MM');
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Informações de Valores Agregados.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '36' ); -- Informações de Valores Agregados
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      for rec in c_iva (vn_multorg_id) loop
         exit when c_iva%notfound or (c_iva%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            to_date(rec.mes||'/'||rec.ano,'MM/RRRR') > vd_dt_ult_fecha then
            --
            delete from r_loteintws_iva
             where infvaloragreg_id = rec.id;
            --
            delete from inf_valor_agreg iva
             where iva.id = rec.id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Informações de Valores Agregados não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 4;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir as Informações de Valores Agregados. Verifique (pk_despr_integr.pkb_despr_iva): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_iva fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_iva;

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Controle de Creditos Fiscais de ICMS
------------------------------------------------------------------------------------------
procedure pkb_despr_cf_icms ( en_empresa_id in empresa.id%Type
                            , en_usuario_id in neo_usuario.id%type
                            , ed_dt_ini     in date
                            , ed_dt_fin     in date
                            )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              contr_cred_fiscal_icms.id%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_cf_icms (en_multorg_id mult_org.id%type) is
      select cc.id
           , to_date(cc.mes||'/'||cc.ano,'MM/RRRR') dt
           , cc.empresa_id
        from empresa e
           , usuario_empresa ue
           , contr_cred_fiscal_icms cc
       where e.multorg_Id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and cc.empresa_id = e.id
         and cc.empresa_id = nvl(en_empresa_id,cc.empresa_id)
         and to_date(cc.mes||'/'||cc.ano,'MM/RRRR') between trunc(ed_dt_ini,'MM') and trunc(ed_dt_fin,'MM')
    order by id;
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Controle de Créditos Fiscais de ICMS.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '39' ); -- Controle de Creditos Fiscais de ICMS
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      for rec in c_cf_icms (vn_multorg_id) loop
         exit when c_cf_icms%notfound or (c_cf_icms%notfound) is null;
         --
         vn_fase := 4;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            rec.dt > vd_dt_ult_fecha then
            --
            vn_fase := 6;
            --
            vn_id := rec.id;
            --
            delete from util_cred_fiscal_icms where contrcredfiscalicms_id = rec.id;
            --
            vn_fase := 6.1;
            --
            delete from r_loteintws_ccficms where contrcredfiscalicms_id = rec.id;
            --
            vn_fase := 7;
            --
            delete from contr_cred_fiscal_icms where id = rec.id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Controle de Creditos Fiscais de ICMS não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Controle de Crédito Fiscal ICMS (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_cf_icms): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_cf_icms fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_cf_icms;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Total de operações com cartão
------------------------------------------------------------------------------------------
procedure pkb_despr_tot_op_cart ( en_empresa_id in empresa.id%Type
                                , en_usuario_id in neo_usuario.id%type
                                , ed_dt_ini     in date
                                , ed_dt_fin     in date
                                )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_toc (en_multorg_id mult_org.id%type) is
      select toc.id
           , toc.empresa_id
           , toc.mes
           , toc.ano
        from total_oper_cartao toc
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and toc.empresa_id = nvl(en_empresa_id, toc.empresa_id)
         and e.id = toc.empresa_id
         and to_date(toc.mes||'/'||toc.ano,'MM/RRRR') between trunc(ed_dt_ini,'MM') and trunc(ed_dt_fin,'MM');
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Total de Operações com Cartão.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '42' ); -- Total de Operações com Cartão
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      for rec in c_toc (vn_multorg_id) loop
         exit when c_toc%notfound or (c_toc%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            to_date(rec.mes||'/'||rec.ano,'MM/RRRR') > vd_dt_ult_fecha then
            --
            delete from r_loteintws_toc
             where totalopercartao_id = rec.id;
            --
            delete from total_oper_cartao toc
             where toc.id = rec.id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Total de Operações com Cartão não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 4;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Total de Operação de Cartão. Verifique (pk_despr_integr.pkb_despr_tot_op_cart): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_tot_op_cart fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_tot_op_cart;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar DIRF
------------------------------------------------------------------------------------------
procedure pkb_despr_dirf ( en_empresa_id in empresa.id%Type
                         , en_usuario_id in neo_usuario.id%type
                         , ed_dt_ini     in date
                         , ed_dt_fin     in date
                         )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              inf_rend_dirf.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   vn_objintegr_id    obj_integr.id%type;
   --
   cursor c_dirf (en_multorg_id mult_org.id%type) is
   select i.id  id
        , i.empresa_id
        , i.ano_ref
     from empresa e
        , usuario_empresa ue
        , inf_rend_dirf i
    where e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and i.empresa_id = e.id
      and i.ano_ref     between to_number(to_char(ed_dt_ini,'YYYY')) and to_number(to_char(ed_dt_fin,'YYYY'))
      and i.empresa_id        = nvl(en_empresa_id, i.empresa_id)
      and i.dm_tipo_lcto not in (5) -- não seja "Manual"
      and not exists (select 1 from r_gera_inf_rend_dirf r where r.infrenddirf_id = i.id)
    order by i.id;
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Informações da DIRF.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '47' ); -- Informações da DIRF
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      for rec in c_dirf (vn_multorg_id) loop
         exit when c_dirf%notfound or (c_dirf%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            to_date(to_char(rec.ano_ref), 'YYYY') > vd_dt_ult_fecha then
            --
            vn_id := rec.id;
            --
            vn_fase := 4;
            --
            begin
               delete from inf_rend_dirf_pse
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - inf_rend_dirf_pse - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 5;
            --
            begin
               delete from inf_rend_dirf_anual
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - inf_rend_dirf_anual - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 6;
            --
            begin
               delete from inf_rend_dirf_mensal
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - inf_rend_dirf_mensal - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 7;
            --
            begin
               delete from inf_rend_dirf_pdf
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - inf_rend_dirf_pdf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 8;
            --
            begin
               delete from r_gera_inf_rend_dirf
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - r_gera_inf_rend_dirf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 8.1;
            --
            delete from r_loteintws_ird where infrenddirf_id = rec.id;
            --
            vn_fase := 9;
            --
            begin
               delete from rel_fis_inf_rend_dirf
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - rel_fis_inf_rend_dirf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 9.1;
            --
            begin
               delete from rel_jur_it_inf_rend_dirf
                where reljurinfrenddirf_id in (select id
                                                from rel_jur_inf_rend_dirf
                                               where infrenddirf_id = rec.id);
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - rel_jur_it_inf_rend_dirf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 9.2;
            --
            begin
               delete from rel_jur_inf_rend_dirf
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - rel_jur_inf_rend_dirf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 9.3;
            --
            begin
               delete from inf_rend_dirf_rpde
                where infrenddirf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - inf_rend_dirf_rpde - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 9.4;
            --
            begin
               delete from inf_rend_dirf
                where id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dirf - inf_rend_dirf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 10;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Informações da DIRF não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 11;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Informe de Rendimento - DIRF (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_dirf): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_dirf fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_dirf;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Pagamento de Impostos no padrão para DCTF
------------------------------------------------------------------------------------------
procedure pkb_despr_pgto_imp_ret ( en_empresa_id in empresa.id%Type
                                 , en_usuario_id in neo_usuario.id%type
                                 , ed_dt_ini     in date
                                 , ed_dt_fin     in date
                                 )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   vn_qtde            number;
   --
   vn_empresa_id      number;
   vn_exist           number;
   vd_dt_fech_evento  date;
   VN_EXIST_EVENTO    number;
   --
   cursor c_pir (en_multorg_id mult_org.id%type) is
      select pir.id
           , pir.empresa_id
           , pir.dt_pgto
           , pir.nro_doc
           , pir.tiporetimp_id
        from pgto_imp_ret pir
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and pir.empresa_id = nvl(en_empresa_id, pir.empresa_id)
         and e.id = pir.empresa_id
         and nvl(pir.dt_docto, pir.dt_pgto) between trunc(ed_dt_ini) and trunc(ed_dt_fin);
        -- and nvl(pir.DT_PGTO, pir.dt_vcto) between trunc(ed_dt_ini) and trunc(ed_dt_fin);
   --
   cursor c_irrp (en_multorg_id mult_org.id%type) is
      select i.id impretrecpc_id
           , i.empresa_id
           , i.dt_ret
        from imp_ret_rec_pc i
           , empresa e
           , usuario_empresa ue
       where e.multorg_id = en_multorg_id
         and ue.empresa_id = e.id
         and ue.usuario_id = en_usuario_id
         and i.empresa_id = nvl(en_empresa_id, i.empresa_id)
         and e.id = i.empresa_id
         and i.dt_ret between trunc(ed_dt_ini) and trunc(ed_dt_fin);
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if gv_cd_tipo_obj_integr = '1' then
      --
      -- Pagamentos de impostos retidos PCC
      -- Registra log
      if nvl(vn_multorg_id,0) > 0
         or nvl(vn_empresa_id,0) > 0 then
         --
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Pagamentos de Impostos no padrão DCTF - Pagamentos de Impostos Retidos.'
                                  );
         --
         vn_fase := 2;
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '46' ); -- Pagamento de Impostos no Padrão para DCTF
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         vn_fase := 3;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         vn_fase := 4;
         --
         for rec_pir in c_pir (vn_multorg_id) loop
            exit when c_pir%notfound or (c_pir%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec_pir.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            if vd_dt_ult_fecha is null or
               rec_pir.dt_pgto > vd_dt_ult_fecha then
               --
               vn_fase := 4.1;
               vn_exist := null;
               --
               begin
                  --
                  select distinct 1
                    into vn_exist
                    from det_ger_pgto_imp_ret dg
                   where dg.pgtoimpret_id = rec_pir.id;
                  --
               exception
                when no_data_found then
                   vn_exist := null;
               end;
               --
               -- Buscar a data do fechamento de declaração do REINF para o pagamento do Imposto Retido
               vd_dt_fech_evento :=  pk_csf_reinf.fkg_max_data_envio_reinf ( rec_pir.dt_pgto );
               --
               vn_fase := 4.2;
               --
               -- Verificar se houve um novo Evento criado/Enviado até a data do Fechamento para este Pagamento de Imposto Retido
               vn_exist_evento := null;
               --
               begin
                  select distinct 1
                    into vn_exist_evento
                    from efd_reinf_r2070 efd
                       , lote_efd_reinf lt
                   where nvl(lt.dt_hr_envio,lt.dt_hr_abert) between rec_pir.dt_pgto and vd_dt_fech_evento
                     and tiporetimp_id = rec_pir.tiporetimp_id
                     and efd.loteefdreinf_id = lt.id;
               exception
                when others then
                  vn_exist_evento := null;
               end;
               --
               vn_fase := 4.3;
               --
               if nvl(vn_exist,0) <> 1
                and nvl(vn_exist_evento,0) <> 1 then
                  --
                  delete from r_loteintws_pir
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.4;
                  --
                  delete from pir_comp_jud
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.5;
                  --
                  delete from pir_det_comp
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.6;
                  --
                  delete from pir_det_ded
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.7;
                  --
                  delete from pir_inf_rra_desp_adv
                   where pirinfrradesp_id in ( select pdesp.id
                                                 from pir_inf_rra prr
                                                    , pir_inf_rra_desp pdesp
                                                where prr.id  = pdesp.pirinfrra_id
                                                  and prr.pgtoimpret_id = rec_pir.id );
                  --
                  vn_fase := 4.8;
                  --
                  delete from pir_inf_rra_desp
                   where pirinfrra_id in ( select id
                                            from pir_inf_rra
                                           where pgtoimpret_id = rec_pir.id );
                  --
                  vn_fase := 4.9;
                  --
                  delete from pir_inf_rra
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.10;
                  --
                  delete from pir_proc_reinf_desp_adv
                   where pirprocreinfdesp_id in ( select pprd.id
                                                    from pir_proc_reinf ppr
                                                       , pir_proc_reinf_desp pprd
                                                   where ppr.pgtoimpret_id = rec_pir.id
                                                     and ppr.id = pprd.pirprocreinf_id );
                  --
                  vn_fase := 4.11;
                  --
                  delete from pir_proc_reinf_desp
                   where pirprocreinf_id in ( select id
                                                from pir_proc_reinf
                                              where pgtoimpret_id = rec_pir.id );
                  --
                  vn_fase := 4.12;
                  --
                  delete from pir_proc_reinf_orig_rec
                   where pirprocreinf_id in ( select id
                                                from pir_proc_reinf
                                              where pgtoimpret_id = rec_pir.id );
                  --
                  vn_fase := 4.13;
                  --
                  delete from pir_proc_reinf
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.14;
                  --
                  delete from pir_rend_isento
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.15;
                  --
                  delete from pir_info_ext
                   where pgtoimpret_id = rec_pir.id;
                  --
                  vn_fase := 4.16;
                  --
                  delete from pgto_imp_ret pir
                   where pir.id = rec_pir.id;
                  --
               else
                  -- Gerar log no agendamento devido a data de fechamento
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => 'Não pode ser desprocessada o Pagamento de Imposto Retido ( Nro: '|| rec_pir.nro_doc || ' e Data pgto: '|| rec_pir.dt_pgto ||'). Pois existem registros '||
                                                                          'na tabela de "Geração de Pagamentos de Impostos Retidos" relacionados a este Pagamento de Imposto Retido, Favor Verificar na Tela Sped '||
                                                                          '-> Impostos Retidos -> Geração de Pagamento de Impostos Retidos.'
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => 1
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => nvl(gn_empresa_id,en_empresa_id)
                                                   );
                  --
               end if;
               --
               vn_fase := 4.17;
               --
            else
               --
               if nvl(vn_exist,0) = 1 then
                  -- Gerar log no agendamento devido a data de fechamento
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => 'Período informado para desprocessar a integração de Pagamento de Impostos no Padrão para DCTF não '||
                                                                          'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                   , en_tipo_log       => info_fechamento
                                                   , en_referencia_id  => null
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   );
               end if;
               --
               if nvl(vn_exist_evento,0) = 1 then
                  -- Gerar log no agendamento devido a data de fechamento
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => 'Pagamento de Imposto Retido não pode ser Desprocessado por conta que existe Evento Enviado Para o REINF ('||
                                                                          'Nro. Documento: '|| rec_pir.nro_doc || ' e Data pgto: '|| rec_pir.dt_pgto ||'), Favor Verificar.'
                                                   , en_tipo_log       => info_fechamento
                                                   , en_referencia_id  => null
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   );
               end if;
               --
            end if;
            --
         end loop;
         --
         commit;
         --
         -- Garante que desprocesse apenas o tipo de objeto em questão.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '2' then
      --
      -- Impostos retidos sobre recieta de serviços
      -- Registra log
      if nvl(vn_multorg_id,0) > 0
         or nvl(vn_empresa_id,0) > 0 then
         --
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Pagamentos de Impostos no padrão DCTF - Impostos Retidos sobre Receita de Serviços.'
                                  );
         --
         if nvl(gn_objintegr_id,0) = 0 then
            vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '46' ); -- Pagamento de Impostos no Padrão para DCTF
         else
            vn_objintegr_id := gn_objintegr_id;
         end if;
         --
         vn_fase := 5;
         --
         if nvl(en_empresa_id,0) > 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
            if nvl(vn_multorg_id,0) = 0 then
               --
               vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
               --
            end if;
            --
         end if;
         --
         begin
            --
            select count(1) into vn_qtde
              from gera_contr_ret_fonte_pc
             where empresa_id in ( select e.id
                                      from empresa e
                                         , usuario_empresa ue
                                   where e.multorg_id = vn_multorg_id
                                     and ue.empresa_id = e.id
                                     and ue.usuario_id = en_usuario_id)
               and dm_st_proc = 1 -- Gerado
               and ( to_number(to_char(dt_ini, 'rrrrmm')) >= to_number(to_char(ed_dt_ini, 'rrrrmm'))
                     and to_number(to_char(dt_fin, 'rrrrmm')) <= to_number(to_char(ed_dt_fin, 'rrrrmm'))
                   );
            --
         exception
            when others then
               vn_qtde := 0;
         end;
         --
         if nvl(vn_qtde,0) <= 0 then
            --
            vn_fase := 6;
            --
            for rec_irrp in c_irrp (vn_multorg_id) loop
               exit when c_irrp%notfound or (c_irrp%notfound) is null;
               --
               vn_fase := 6.1;
               --
               if nvl(en_empresa_id,0) = 0 then
                  --
                  vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec_irrp.empresa_id -- en_empresa_id
                                                                             , vn_objintegr_id ) -- en_objintegr_id
                                       , (ed_dt_ini - 1));
                  --
               end if;
               --
               if vd_dt_ult_fecha is null or
                  rec_irrp.dt_ret > vd_dt_ult_fecha then
                  --
                  vn_fase := 6.2;
                  --
                  delete from imp_ret_rec_pc_nf inf
                   where inf.impretrecpc_id = rec_irrp.impretrecpc_id;
                  --
                  vn_fase := 6.3;
                  --
                  delete from r_loteintws_irrpc
                   where impretrecpc_id = rec_irrp.impretrecpc_id;
                  --
                  vn_fase := 6.4;
                  --
                  delete from imp_ret_rec_pc i
                   where i.id = rec_irrp.impretrecpc_id;
                  --
               else
                  --
                  vn_fase := 6.5;
                  --
                  -- Gerar log no agendamento devido a data de fechamento
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => 'Período informado para desprocessar a integração de Pagamento de Impostos no Padrão para DCTF não '||
                                                                          'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                   , en_tipo_log       => info_fechamento
                                                   , en_referencia_id  => null
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   );
                  --
               end if;
               --
            end loop;
            --
         else
            --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Pagamento de Impostos no Padrão para DCTF não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => informacao
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
         commit;
         --
         -- Garante que desprocesse apenas o tipo de objeto em questão.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   end if;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(vn_empresa_id,0) > 0 then
      --
      vn_fase := 7;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Pagamento de Impostos no padrão DCTF.'
                               );
      --
      vn_fase := 8;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '46' ); -- Pagamento de Impostos no Padrão para DCTF
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 9;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      for rec_pir in c_pir (vn_multorg_id) loop
         exit when c_pir%notfound or (c_pir%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec_pir.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            rec_pir.dt_pgto > vd_dt_ult_fecha then
            --
            vn_fase := 10;
            vn_exist := null;
            --
            begin
               --
               select distinct 1
                 into vn_exist
                 from det_ger_pgto_imp_ret dg
                where dg.pgtoimpret_id = rec_pir.id;
               --
            exception
             when no_data_found then
                vn_exist := null;
            end;
            --
            vn_fase := 11;
            --
            if nvl(vn_exist,0) <> 1 then
               --
               delete from r_loteintws_pir
                where pgtoimpret_id = rec_pir.id;
               --
               vn_fase := 11.1;
               --
               delete from pir_info_ext
                   where pgtoimpret_id = rec_pir.id;
               --
               vn_fase := 11.2;
               --
               delete from pgto_imp_ret pir
                where pir.id = rec_pir.id;
               --
            else
               --
               -- Gerar log no agendamento devido a data de fechamento
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => 'Não pode ser desprocessada o Pagamento de Imposto Retido ( Nro: '|| rec_pir.nro_doc || ' e Data pgto: '|| rec_pir.dt_pgto ||'). Pois existem registros '||
                                                                          'na tabela de "Geração de Pagamentos de Impostos Retidos" relacionados a este Pagamento de Imposto Retido, Favor Verificar na Tela Sped '||
                                                                          '-> Impostos Retidos -> Geração de Pagamento de Impostos Retidos.'
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => 1
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => nvl(gn_empresa_id,en_empresa_id)
                                                   );
               --
            end if;
            --
         else
            --
            vn_fase := 12;
            --
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Pagamento de Impostos no Padrão para DCTF não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 13;
      --
      --| Verifica se existe "Impostos Retidos Sobre Receita" Gerados no F600
      begin
         --
         select count(1) into vn_qtde
           from gera_contr_ret_fonte_pc
          where empresa_id in ( select e.id
                                   from empresa e
                                      , usuario_empresa ue
                                where e.multorg_id = vn_multorg_id
                                  and ue.empresa_id = e.id
                                  and ue.usuario_id = en_usuario_id)
            and dm_st_proc = 1 -- Gerado
            and ( to_number(to_char(dt_ini, 'rrrrmm')) >= to_number(to_char(ed_dt_ini, 'rrrrmm'))
                  and to_number(to_char(dt_fin, 'rrrrmm')) <= to_number(to_char(ed_dt_fin, 'rrrrmm'))
                );
         --
      exception
         when others then
            vn_qtde := 0;
      end;
      --
      if nvl(vn_qtde,0) <= 0 then
         --
         vn_fase := 14;
         --
         for rec_irrp in c_irrp (vn_multorg_id) loop
            exit when c_irrp%notfound or (c_irrp%notfound) is null;
            --
            vn_fase := 14.1;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec_irrp.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                    , (ed_dt_ini - 1));
               --
            end if;
            --
            if vd_dt_ult_fecha is null or
               rec_irrp.dt_ret > vd_dt_ult_fecha then
               --
               vn_fase := 14.2;
               --
               delete from imp_ret_rec_pc_nf inf
                where inf.impretrecpc_id = rec_irrp.impretrecpc_id;
               --
               vn_fase := 14.3;
               --
               delete from r_loteintws_irrpc
                where impretrecpc_id = rec_irrp.impretrecpc_id;
               --
               vn_fase := 14.4;
               --
               delete from imp_ret_rec_pc i
                where i.id = rec_irrp.impretrecpc_id;
               --
            else
               --
               vn_fase := 14.5;
               --
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar a integração de Pagamento de Impostos no Padrão para DCTF não '||
                                                                       'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         end loop;
         --
      else
         --
         -- Gerar log no agendamento devido a data de fechamento
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                          , ev_mensagem       => 'Desprocessar Integração'
                                          , ev_resumo         => 'Período informado para desprocessar a integração de Pagamento de Impostos no Padrão para DCTF não '||
                                                                 'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                          , en_tipo_log       => informacao
                                          , en_referencia_id  => null
                                          , ev_obj_referencia => 'DESPR_INTEGR'
                                          , en_empresa_id     => gn_empresa_id
                                          );
         --
      end if;
      --
      vn_fase := 15;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir os Pagamentos de Impostos Retidos. Verifique (pk_despr_integr.pkb_despr_pgto_imp_ret) fase ('|| vn_fase ||'): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_pgto_imp_ret fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_pgto_imp_ret;

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Créditos para DCTF
------------------------------------------------------------------------------------------
procedure pkb_despr_imp_cred_dctf ( en_empresa_id in empresa.id%Type
                                 , en_usuario_id in neo_usuario.id%type
                                 , ed_dt_ini     in date
                                 , ed_dt_fin     in date
                                 )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              inf_rend_dirf.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   vn_objintegr_id    obj_integr.id%type;
   --
   cursor c_cred (en_multorg_id mult_org.id%type) is
    select d.id
         , d.empresa_id
         , d.dt_periodo_apur
    from imp_cred_dctf d
    , empresa e
    , usuario_empresa ue
    where (trunc(d.dt_periodo_apur ) >= trunc(ed_dt_ini) and trunc(d.dt_periodo_apur ) <= trunc(ed_dt_fin))
       and d.empresa_id    = nvl(en_empresa_id, d.empresa_id)
      and e.id = d.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id ;
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Créditos para DCTF.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '46' ); -- Créditos para DCTF
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      for rec in c_cred (vn_multorg_id) loop
         exit when c_cred%notfound or (c_cred%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_periodo_apur > vd_dt_ult_fecha then
            --
            vn_id := rec.id;
            --
            vn_fase := 4;
            --
            begin
               delete from imp_cred_dctf_darf
                where impcreddctf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_imp_cred_dctf - imp_cred_dctf_darf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 5;
            --
            begin
               delete from imp_cred_dctf_comp
                where impcreddctf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_imp_cred_dctf - imp_cred_dctf_comp - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
            vn_fase := 6;
            --
            begin
               delete from imp_cred_dctf_susp
                where impcreddctf_id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_imp_cred_dctf - imp_cred_dctf_susp - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --
             vn_fase := 7;
            --
            begin
               delete from imp_cred_dctf
                where id = rec.id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_imp_cred_dctf - imp_cred_dctf - fase ('||vn_fase||'): '||sqlerrm);
            end;
            --

         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Créditos para DCTF não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir os Créditos para DCTF. Verifique (pk_despr_integr.pkb_despr_imp_cred_dctf) fase ('|| vn_fase ||'): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_imp_cred_dctf fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_imp_cred_dctf;

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar Controle da Produção e do Estoque
------------------------------------------------------------------------------------------
procedure pkb_despr_contr_prod_estq ( en_empresa_id in empresa.id%Type
                                    , en_usuario_id in neo_usuario.id%type
                                    , ed_dt_ini     in date
                                    , ed_dt_fin     in date
                                    )
is
   --
   pragma             autonomous_transaction;
   vn_fase            number := 0;
   vn_id              per_contr_prod_estq.id%type;
   vn_objintegr_id    obj_integr.id%type;
   vn_loggenerico_id  log_generico.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_per (en_multorg_id mult_org.id%type) is
   select pc.id percontrprodestq_id
        , pc.empresa_id
        , pc.dt_ini
        , pc.dt_fin
     from empresa e
        , usuario_empresa ue
        , per_contr_prod_estq pc
    where e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and pc.empresa_id = nvl(en_empresa_id, pc.empresa_id)
      and pc.empresa_id = e.id
      and pc.dt_ini    >= ed_dt_ini
      and pc.dt_fin    <= ed_dt_fin;
   --
   cursor c_car (en_percontrprodestq_id per_contr_prod_estq.id%type) is
   select car.id
     from corr_apont_reg car
    where car.percontrprodestq_id = en_percontrprodestq_id;
   --
   cursor c_rrpi (en_percontrprodestq_id per_contr_prod_estq.id%type) is
   select rrpi.id
     from repr_repa_prod_ins rrpi
    where rrpi.percontrprodestq_id = en_percontrprodestq_id;
   --
   cursor c_dmio (en_percontrprodestq_id per_contr_prod_estq.id%type) is
   select dmio.id
     from desmon_merc_item_orig dmio
    where dmio.percontrprodestq_id = en_percontrprodestq_id;
   --
   cursor c_pcit (en_percontrprodestq_id per_contr_prod_estq.id%type) is
   select pcit.id prodcjtaindterc_id
   from prod_cjta_indterc pcit where pcit.percontrprodestq_id = en_percontrprodestq_id;
   --
   cursor c_pcop (en_percontrprodestq_id per_contr_prod_estq.id%type)is
   select pcop.id prodcjtaordprod_id
   from prod_cjta_ordprod pcop where pcop.percontrprodestq_id = en_percontrprodestq_id;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1.1;
      --
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Controle da Produção e do Estoque.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '48' ); -- Controle da Produção e do Estoque
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      for r_per in c_per(vn_multorg_id) loop
         exit when c_per%notfound or (c_per%notfound) is null;
         --
         vn_fase := 5;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( r_per.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            r_per.dt_ini > vd_dt_ult_fecha then
            --
            vn_id := r_per.percontrprodestq_id;
            --
            vn_fase := 6;
            --
            begin
               delete from industr_em_terc ie
                where ie.industrporterc_id in (select ip.id
                                                 from industr_por_terc ip
                                                where ip.percontrprodestq_id = r_per.percontrprodestq_id);
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Industrialização em Terceiros (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 7;
            --
            begin
               delete from industr_por_terc ip
                where ip.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Industrialização por Terceiros (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 8;
            --
            begin
               delete from insumo_cons ic
                where ic.itemproduz_id in (select ip.id
                                             from item_produz ip
                                            where ip.percontrprodestq_id = r_per.percontrprodestq_id);
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Insumos Consumidos (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 9;
            --
            begin
               delete item_produz ip
                where ip.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens Produzidos (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 10;
            --
            begin
               delete outr_movto_inter_merc om
                where om.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Outras movimentações internas entre Mercadorias ('||
                                                  'pk_despr_integr.pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||
                                                  r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 11;
            --
            begin
               delete estq_escrit ee
                where ee.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 13;
            --
            delete from r_loteintws_pcpe where percontrprodestq_id = r_per.percontrprodestq_id;
            --
            vn_fase := 14;
            --
            for r_car in c_car(r_per.percontrprodestq_id) loop
               exit when c_car%notfound or (c_car%notfound) is null;
               --
               vn_fase := 14.1;
               --
               begin
                  delete corr_apont_ret_ins cari
                   where cari.corrapontreg_id = r_car.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' corrapontreg_id = '||r_car.id||'): '||sqlerrm);
               end;
               --
            end loop;
            --
            vn_fase := 15;
            --
            begin
               delete corr_apont_reg car
                where car.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            for r_rrpi in c_rrpi(r_per.percontrprodestq_id) loop
               exit when c_rrpi%notfound or (c_rrpi%notfound) is null;
               --
               vn_fase := 15.1;
               --
               begin
                  delete repr_repa_merc_cons_ret rrmcr
                   where rrmcr.reprrepaprodins_id = r_rrpi.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' reprrepaprodins_id = '||r_rrpi.id||'): '||sqlerrm);
               end;
               --
            end loop;
            --
            vn_fase := 16;
            --
            begin
               delete repr_repa_prod_ins rrpi
                where rrpi.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            for r_dmio in c_dmio(r_per.percontrprodestq_id) loop
               exit when c_dmio%notfound or (c_dmio%notfound) is null;
               --
               vn_fase := 16.1;
               --
               begin
                  delete desmon_merc_item_dest dmid
                   where dmid.desmonmercitemorig_id = r_dmio.id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' desmonmercitemorig_id = '||r_dmio.id||'): '||sqlerrm);
               end;
               --
            end loop;
            --
            vn_fase := 17;
            --
            begin
               delete desmon_merc_item_orig dmio
                where dmio.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 18;
            --
            begin
               delete corr_apont_est cae
                where cae.percontrprodestq_id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Controle da Produção e do Estoque - Itens de estoque escriturado (pk_despr_integr.'||
                                                  'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 19;
            --
            begin
               delete per_contr_prod_estq pc
                where pc.id = r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Período de controle da produção e do estoque (pk_despr_integr.pkb_despr_contr_prod_estq '||
                                                  'fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 20;
            --
            for r_pcit in c_pcit(r_per.percontrprodestq_id) loop
               exit when c_pcit%notfound or (c_pcit%notfound) is null;
               --
               vn_fase := 20.1;
               --
               begin
                  delete from prod_cjta_indterc_ic pcitic
                   where pcitic.prodcjtaindterc_id  = r_pcit.prodcjtaindterc_id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Produção Conjunta - Itens Produzidos  (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' prodcjtaindterc_id = '||r_pcit.prodcjtaindterc_id||'): '||sqlerrm);
               end;
               --
               vn_fase := 20.2;
               --
               begin
                  delete from prod_cjta_indterc_ip pcitip
                   where pcitip.prodcjtaindterc_id  = r_pcit.prodcjtaindterc_id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Produção Conjunta - Insumos Consumidos  (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' prodcjtaindterc_id = '||r_pcit.prodcjtaindterc_id||'): '||sqlerrm);
               end;
               --
            end loop;
            --
            vn_fase := 21;
            --
            begin
                delete from prod_cjta_indterc pcit where pcit.percontrprodestq_id =  r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Produção Conjunta - Ordem de Produção (pk_despr_integr.pkb_despr_contr_prod_estq '||
                                                  'fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
            vn_fase := 22;
            --
            for r_pcop in c_pcop(r_per.percontrprodestq_id) loop
               exit when c_pcop%notfound or (c_pcop%notfound) is null;
               --
               vn_fase := 22.1;
               --
               begin
                  delete from prod_cjta_inscons pcic
                   where pcic.prodcjtaordprod_id   = r_pcop.prodcjtaordprod_id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Produção Conjunta - Industrialização efetuada por Terceiros - Itens Produzidos   (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' prodcjtaordprod_id = '||r_pcop.prodcjtaordprod_id||'): '||sqlerrm);
               end;
               --
               vn_fase := 22.2;
               --
               begin
                  delete from prod_cjta_itemprod pcip
                   where pcip.prodcjtaordprod_id   = r_pcop.prodcjtaordprod_id;
               exception
                  when others then
                     raise_application_error(-20101, 'Problemas ao excluir Produção Conjunta - Industrialização efetuada por Terceiros - Insumos Consumidos   (pk_despr_integr.'||
                                                     'pkb_despr_contr_prod_estq fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||' prodcjtaordprod_id = '||r_pcop.prodcjtaordprod_id||'): '||sqlerrm);
               end;
               --
            end loop;
            --
            vn_fase := 23;
            --
            begin
                delete from prod_cjta_ordprod pcop where pcop.percontrprodestq_id =  r_per.percontrprodestq_id;
            exception
               when others then
                  raise_application_error(-20101, 'Problemas ao excluir Produção Conjunta - Industrialização efetuada por Terceiros  (pk_despr_integr.pkb_despr_contr_prod_estq '||
                                                  'fase '||vn_fase||' en_percontrprodestq_id = '||r_per.percontrprodestq_id||'): '||sqlerrm);
            end;
            --
         else
            --
            vn_fase := 24;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de Controle da Produção e do Estoque não '||
                                                                    'permitido devido a data de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 25;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Período de controle da produção e do estoque (id = '||'). Verifique (pk_despr_integr.pkb_despr_contr_prod_estq): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_contr_prod_estq fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_contr_prod_estq;

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar as informações do Sped ECF
------------------------------------------------------------------------------------------
procedure pkb_despr_dados_secf ( en_empresa_id in empresa.id%type
                               , en_usuario_id in neo_usuario.id%type
                               , ed_dt_ini     in date
                               , ed_dt_fin     in date
                               )
is
   --
   vn_fase                number := null;
   vn_multorg_id          mult_org.id%type;
   vn_loggenerico_id      log_generico.id%type;
   vn_objintegr_id        obj_integr.id%type;
   vd_dt_ult_fecha        fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_empresa_id          empresa.id%type;
   vn_qtde_sped_ecf      number;
   --
begin
   --
   vn_fase := 1;
   --
   gn_empresa_id := en_empresa_id;
   --
   vn_multorg_id := gn_multorg_id;
   --
   vn_empresa_id := en_empresa_id;
   --
   vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '27' );
   --
   -- Verificar se ja Existe Abertura_Ecf para esta empresa que Dentro desse periodo
   vn_fase := 2.1;
   begin
      --
      select count(1)
        into vn_qtde_sped_ecf
        from abertura_ecf
       where empresa_id = en_empresa_id
         and dm_situacao <> 0 -- Aberto
/*         and ( to_number(to_char(dt_ini, 'RRRR')) <= to_number(to_char(ed_dt_ini, 'RRRR'))
               and to_number(to_char(dt_fin, 'RRRR')) >= to_number(to_char(ed_dt_fin, 'RRRR'))
             );*/
        and ( to_date(dt_ini,gv_formato_data) <= to_date(ed_dt_ini,gv_formato_data)
              and to_date(dt_fin,gv_formato_data) >= to_date(ed_dt_fin,gv_formato_data)
             );
      --
   exception
      when others then
         vn_qtde_sped_ecf := 0;
   end;
   --
   vn_fase := 2.2;
   --
   if nvl(vn_qtde_sped_ecf,0) > 0 then
      --
      vn_fase := 3;
      -- Gerar log no agendamento devido a data de fechamento
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => 'Existe Abertura de SPED ECF para a empresa '||  pk_csf.fkg_cod_nome_empresa_id (en_empresa_id) ||
                                                              ' ja em andamento para este periodo, Favor Verificar Antes de Efetuar o Desprocessamento.'
                                       , en_tipo_log       => info_fechamento
                                       , en_referencia_id  => null
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       );
      --
      goto sair_proc;
      --
   end if;
   --
   if gv_cd_tipo_obj_integr = '1' then
      --
      -- Views Dinâmicas do ECF
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Lançamentos de Valores para os Registros de Tabela Dinâmica.'
                                  );
         --
         vn_fase := 4;
         --
         begin
            --
            delete from lcto_part_a_lacs_lalur
             where ccrlancpart_id in ( select cc.id
                                           from lanc_vlr_tab_din lv
                                              , ccr_lanc_part    cc
                                          where lv.empresa_id       = nvl(en_empresa_id, lv.empresa_id)
                                            and cc.lancvlrtabdin_id = lv.id
                                            and lv.dt_ini           >= ed_dt_ini
                                            and lv.dt_fim           <= ed_dt_fin
                                            and lv.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( lv.empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1)));
            --
            vn_fase := 5;
            --
            delete from ccr_lanc_part
             where lancvlrtabdin_id in ( select id
                                           from lanc_vlr_tab_din lv
                                          where lv.empresa_id       = nvl(en_empresa_id, lv.empresa_id)
                                            and lv.dt_ini           >= ed_dt_ini
                                            and lv.dt_fim           <= ed_dt_fin
                                            and lv.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( lv.empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1)));
            vn_fase := 5.2;
            --
            delete from conta_part_b
             where lancvlrtabdin_id in ( select id
                                           from lanc_vlr_tab_din lv
                                          where lv.empresa_id       = nvl(en_empresa_id, lv.empresa_id)
                                            and lv.dt_ini           >= ed_dt_ini
                                            and lv.dt_fim           <= ed_dt_fin
                                            and lv.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( lv.empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1)));
            --
            vn_fase := 6;
            --
            delete from r_loteintws_lvtd
             where lancvlrtabdin_id in ( select id
                             from lanc_vlr_tab_din lv
                            where lv.empresa_id       = nvl(en_empresa_id, lv.empresa_id)
                              and lv.dt_ini           >= ed_dt_ini
                              and lv.dt_fim           <= ed_dt_fin
                              and lv.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( lv.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
            vn_fase := 7;
            --
            delete from lanc_vlr_tab_din
             where id in ( select id
                             from lanc_vlr_tab_din lv
                            where lv.empresa_id       = nvl(en_empresa_id, lv.empresa_id)
                              and lv.dt_ini           >= ed_dt_ini
                              and lv.dt_fim           <= ed_dt_fin
                              and lv.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( lv.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - lanc_vlr_tab_din - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '2' then
      --
      -- Demonstrativo do Livro Caixa - Q100
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Demonstrativo do Livro Caixa - Q100.'
                                  );
         --
         vn_fase := 8;
         --
         begin
            --
            vn_fase := 9;
            --
            delete from r_loteintws_dlc
             where demlivrocaixa_id in ( select id
                             from dem_livro_caixa dl
                            where dl.empresa_id       = nvl(en_empresa_id, dl.empresa_id)
                              and dl.dt_demon between ed_dt_ini and ed_dt_fin
                              and dl.dm_tipo          in (3,4)
                              and dl.dt_demon           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dl.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
            vn_fase := 10;
            --
            delete from LOG_DEM_LIVRO_CAIXA
              where demlivrocaixa_id in ( select id
                             from dem_livro_caixa dl
                            where dl.empresa_id       = nvl(en_empresa_id, dl.empresa_id)
                              and dl.dt_demon between ed_dt_ini and ed_dt_fin
                              and dl.dm_tipo          in (3,4)
                              and dl.dt_demon           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dl.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
            delete from dem_livro_caixa
             where id in ( select id
                             from dem_livro_caixa dl
                            where dl.empresa_id       = nvl(en_empresa_id, dl.empresa_id)
                              and dl.dt_demon between ed_dt_ini and ed_dt_fin
                              and dl.dm_tipo          in (3,4)
                              and dl.dt_demon           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dl.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - dem_livro_caixa - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '3' then
      --
      -- Ativ. Incentivadas de PJ em Geral para Inf. Econômicas X280
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Ativ. Incentivadas de PJ em Geral para Inf. Econômicas X280.'
                                  );
         --
         vn_fase := 11;
         --
         begin
            --
            vn_fase := 12;
            --
            delete from r_loteintws_aiie
             where ativincenieecf_id in ( select id
                             from ativ_incen_ie_ecf ai
                            where ai.empresa_id       = nvl(en_empresa_id, ai.empresa_id)
                              and ai.dt_vig_ini           >= ed_dt_ini
                              and ai.dt_vig_fim           <= ed_dt_fin
                              and ai.dt_vig_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ai.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
            vn_fase := 13;
            --
            delete from log_ativ_incen_ie_ecf
             where ATIVINCENIEECF_ID in ( select id
                             from ativ_incen_ie_ecf ai
                            where ai.empresa_id       = nvl(en_empresa_id, ai.empresa_id)
                              and ai.dt_vig_ini           >= ed_dt_ini
                              and ai.dt_vig_fim           <= ed_dt_fin
                              and ai.dt_vig_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ai.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
            vn_fase := 14;
            --
            delete from ativ_incen_ie_ecf
             where id in ( select id
                             from ativ_incen_ie_ecf ai
                            where ai.empresa_id       = nvl(en_empresa_id, ai.empresa_id)
                              and ai.dt_vig_ini           >= ed_dt_ini
                              and ai.dt_vig_fim           <= ed_dt_fin
                              and ai.dt_vig_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ai.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - ativ_incen_ie_ecf - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '4' then
      --
      -- Operações com o Ext. - Exportações (Entr. de Divisas) X300
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Operações com o Ext. - Exportações (Entr. de Divisas) X300.'
                                  );
         --
         vn_fase := 15;
         --
         begin
            --
            delete from oper_ext_contr_exp_ie
             where operextexportacaoie_id in ( select id
                                                 from oper_ext_exportacao_ie oe
                                                where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                                                  and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                                  and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                       , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 16;
            --
            delete from r_loteintws_oeeie
             where operextexportacaoie_id in ( select id
                             from oper_ext_exportacao_ie oe
                            where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                              and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oe.dm_tipo          in (3,4)
                              and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 17;
            --
            delete from LOG_OPER_EXT_EXPORTACAO_IE
             where operextexportacaoie_id in ( select id
                             from oper_ext_exportacao_ie oe
                            where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                              and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oe.dm_tipo          in (3,4)
                              and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 18;
            --
            delete from oper_ext_exportacao_ie
             where id in ( select id
                             from oper_ext_exportacao_ie oe
                            where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                              and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oe.dm_tipo          in (3,4)
                              and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - oper_ext_exportacao_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '5' then
      --
      -- Operações com o Exterior - Import. (Saída de Divisas) X320
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Operações com o Exterior - Import. (Saída de Divisas) X320.'
                                  );
         --
         vn_fase := 19;
         --
         begin
            --
            delete from oper_ext_contr_imp_ie
             where operextimportacaoie_id in ( select id
                                                 from oper_ext_importacao_ie oe
                                                where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                                                  and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                                  and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                       , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 20;
            --
            delete from r_loteintws_oeiie
             where operextimportacaoie_id in ( select id
                             from oper_ext_importacao_ie oe
                            where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                              and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oe.dm_tipo          in (3,4)
                              and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 21;
            --
            delete from LOG_OPER_EXT_IMPORTACAO_IE
              where operextimportacaoie_id in ( select id
                             from oper_ext_importacao_ie oe
                            where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                              and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oe.dm_tipo          in (3,4)
                              and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 22;
            --
            delete from oper_ext_importacao_ie
             where id in ( select id
                             from oper_ext_importacao_ie oe
                            where oe.empresa_id       = nvl(en_empresa_id, oe.empresa_id)
                              and oe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oe.dm_tipo          in (3,4)
                              and oe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oe.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - oper_ext_importacao_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '6' then
      --
      -- Identificação da Participação no Exterior - X340
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Identificação da Participação no Exterior - X340.'
                                  );
         --
         vn_fase := 23;
         --
         begin
            --
            delete from DEM_CONS_EXT_CONTR_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 24;
            --
            delete from DEM_ESTR_SOC_EXT_CONTR_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 25;
            --
            delete from DEM_PREJ_ACM_EXT_CONTR_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 26;
            --
            delete from DEM_REND_AP_EXT_CONTR_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 27;
            --
            delete from DEM_RES_EXT_AUF_COL_RC_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 28;
            --
            delete from DEM_RESUL_IMP_EXT_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 29;
            --
            delete from LOG_IDENT_PART_EXT_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 30;
            --
            delete from PART_EXT_RESUL_APUR_IE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 31;
            --
            delete from R_LOTEINTWS_IPEIE
             where identpartextie_id in ( select id
                                            from ident_part_ext_ie ip
                                           where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                                             and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                                  , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                  , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 32;
            --
            delete from ident_part_ext_ie
             where id in ( select id
                             from ident_part_ext_ie ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - ident_part_ext_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '7' then
      --
      -- Comércio Eletrônico - Informação de Homepage/Servidor X410
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Informação de Homepage/Servidor X410.'
                                  );
         --
         vn_fase := 33;
         --
         begin
            --
            vn_fase := 34;
            --
            delete from r_loteintws_ceiie
             where comeletinfie_id in ( select id
                             from com_elet_inf_ie ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 35;
            --
            delete from LOG_COM_ELET_INF_IE
             where comeletinfie_id in ( select id
                             from com_elet_inf_ie ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 36;
            --
            delete from com_elet_inf_ie
             where id in ( select id
                             from com_elet_inf_ie ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - com_elet_inf_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '8' then
      --
      -- Comércio Eletrônico - Royalties Receb. ou Pagos Benef. do Brasil e do Exter. X420
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Royalties Receb. ou Pagos Benef. do Brasil e do Exter. X420.'
                                  );
         --
         vn_fase := 37;
         --
         begin
            --
            vn_fase := 38;
            --
            delete from r_loteintws_rrbie
             where royrpbenfie_id in ( select id
                             from roy_rp_benf_ie rr
                            where rr.empresa_id       = nvl(en_empresa_id, rr.empresa_id)
                              and rr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rr.dm_tipo          in (3,4)
                              and rr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 39;
            --
            delete from LOG_ROY_RP_BENF_IE
              where royrpbenfie_id in ( select id
                             from roy_rp_benf_ie rr
                            where rr.empresa_id       = nvl(en_empresa_id, rr.empresa_id)
                              and rr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rr.dm_tipo          in (3,4)
                              and rr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 40;
            --
            delete from roy_rp_benf_ie
             where id in ( select id
                             from roy_rp_benf_ie rr
                            where rr.empresa_id       = nvl(en_empresa_id, rr.empresa_id)
                              and rr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rr.dm_tipo          in (3,4)
                              and rr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - roy_rp_benf_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '9' then
      --
      -- Comércio Eletrônico - Rend. Relativos Serv. Juros Div. Rec. do Brasil e Ext. X430
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Rend. Relativos Serv. Juros Div. Rec. do Brasil e Ext. X430.'
                                  );
         --
         vn_fase := 41;
         --
         begin
            --
            vn_fase := 42;
            --
            delete from r_loteintws_rrrie
             where rendrelrecebie_id in ( select id
                             from rend_rel_receb_ie rr
                            where rr.empresa_id       = nvl(en_empresa_id, rr.empresa_id)
                              and rr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rr.dm_tipo          in (3,4)
                              and rr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 43;
            --
            delete from LOG_REND_REL_RECEB_IE
             where rendrelrecebie_id in ( select id
                                             from rend_rel_receb_ie rr
                                            where rr.empresa_id       = nvl(en_empresa_id, rr.empresa_id)
                                              and rr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and rr.dm_tipo          in (3,4)
                                              and rr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rr.empresa_id
                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 44;
            --
            delete from rend_rel_receb_ie
             where id in ( select id
                             from rend_rel_receb_ie rr
                            where rr.empresa_id       = nvl(en_empresa_id, rr.empresa_id)
                              and rr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rr.dm_tipo          in (3,4)
                              and rr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - rend_rel_receb_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '10' then
      --
      -- Comércio Eletrônico - Pag./Rem. Relat. Serv. Juros Divid. Receb. Brasil Ext. X450
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Pag./Rem. Relat. Serv. Juros Divid. Receb. Brasil Ext. X450'
                                  );
         --
         vn_fase := 45;
         --
         begin
            --
            vn_fase := 46;
            --
            delete from r_loteintws_preie
             where pagrelextie_id in ( select id
                                         from pag_rel_ext_ie pr
                                        where pr.empresa_id       = nvl(en_empresa_id, pr.empresa_id)
                                          and pr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                          and pr.dm_tipo          in (3,4)
                                          and pr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pr.empresa_id
                                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                               , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 47;
            --
            delete from LOG_PAG_REL_EXT_IE
             where pagrelextie_id in ( select id
                                         from pag_rel_ext_ie pr
                                        where pr.empresa_id       = nvl(en_empresa_id, pr.empresa_id)
                                          and pr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                          and pr.dm_tipo          in (3,4)
                                          and pr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pr.empresa_id
                                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                               , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 48;
            --
            delete from pag_rel_ext_ie
             where id in ( select id
                             from pag_rel_ext_ie pr
                            where pr.empresa_id       = nvl(en_empresa_id, pr.empresa_id)
                              and pr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and pr.dm_tipo          in (3,4)
                              and pr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - pag_rel_ext_ie - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '11' then
      --
      -- Comércio Eletrônico - Pagamentos/Recebimentos do Exterior ou Não Residentes Y520
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Pagamentos/Recebimentos do Exterior ou Não Residentes Y520'
                                  );
         --
         vn_fase := 49;
         --
         begin
            --
            vn_fase := 50;
            --
            delete from r_loteintws_penig
             where prextnresidig_id in ( select id
                                           from pr_ext_nresid_ig pe
                                          where pe.empresa_id       = nvl(en_empresa_id, pe.empresa_id)
                                            and pe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and pe.dm_tipo          in (3,4)
                                            and pe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pe.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 51;
            --
            delete from LOG_PR_EXT_NRESID_IG
              where prextnresidig_id in ( select id
                                           from pr_ext_nresid_ig pe
                                          where pe.empresa_id       = nvl(en_empresa_id, pe.empresa_id)
                                            and pe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and pe.dm_tipo          in (3,4)
                                            and pe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pe.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 52;
            --
            delete from pr_ext_nresid_ig
             where id in ( select id
                             from pr_ext_nresid_ig pe
                            where pe.empresa_id       = nvl(en_empresa_id, pe.empresa_id)
                              and pe.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and pe.dm_tipo          in (3,4)
                              and pe.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pe.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - pr_ext_nresid_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '12' then
      --
      -- Comércio Eletrônico - Discr. da Rec. de Vendas dos Estab. por Ativ. Econ. Y540
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Discr. da Rec. de Vendas dos Estab. por Ativ. Econ. Y540'
                                  );
         --
         vn_fase := 53;
         --
         begin
            --
            vn_fase := 54;
            --
            delete from r_loteintws_drecig
             where descrrecestabcnaeig_id in ( select id
                             from descr_rec_estab_cnae_ig dr
                            where dr.empresa_id       = nvl(en_empresa_id, dr.empresa_id)
                              and dr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dr.dm_tipo          in (3,4)
                              and dr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 55;
            --
            delete from LOG_DESCR_REC_ESTAB_CNAE_IG
              where descrrecestabcnaeig_id in ( select id
                             from descr_rec_estab_cnae_ig dr
                            where dr.empresa_id       = nvl(en_empresa_id, dr.empresa_id)
                              and dr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dr.dm_tipo          in (3,4)
                              and dr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 56;
            --
            delete from descr_rec_estab_cnae_ig
             where id in ( select id
                             from descr_rec_estab_cnae_ig dr
                            where dr.empresa_id       = nvl(en_empresa_id, dr.empresa_id)
                              and dr.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dr.dm_tipo          in (3,4)
                              and dr.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dr.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - descr_rec_estab_cnae_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '13' then
      --
      -- Comércio Eletrônico - Vendas a Comerc. Exportadora com Fim Específico de Exp. Y550
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Vendas a Comerc. Exportadora com Fim Específico de Exp. Y550'
                                  );
         --
         vn_fase := 57;
         --
         begin
            --
            vn_fase := 58;
            --
            delete from r_loteintws_vcfeig
             where vendcomfimexpig_id in ( select id
                                             from vend_com_fim_exp_ig vc
                                            where vc.empresa_id       = nvl(en_empresa_id, vc.empresa_id)
                                              and vc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and vc.dm_tipo          in (3,4)
                                              and vc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( vc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 59;
            --
            delete from LOG_VEND_COM_FIM_EXP_IG
             where vendcomfimexpig_id in ( select id
                                             from vend_com_fim_exp_ig vc
                                            where vc.empresa_id       = nvl(en_empresa_id, vc.empresa_id)
                                              and vc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and vc.dm_tipo          in (3,4)
                                              and vc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( vc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 60;
            --
            delete from vend_com_fim_exp_ig
             where id in ( select id
                             from vend_com_fim_exp_ig vc
                            where vc.empresa_id       = nvl(en_empresa_id, vc.empresa_id)
                              and vc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and vc.dm_tipo          in (3,4)
                              and vc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( vc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - descr_rec_estab_cnae_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '14' then
      --
      -- Comércio Eletrônico - Detalhamento das Exportações da Comercial Exportadora Y560
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Detalhamento das Exportações da Comercial Exportadora Y560'
                                  );
         --
         vn_fase := 61;
         --
         begin
            --
            vn_fase := 62;
            --
            delete from r_loteintws_decig
             where detexpcomig_id in ( select id
                                         from det_exp_com_ig de
                                        where de.empresa_id       = nvl(en_empresa_id, de.empresa_id)
                                          and de.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                          and de.dm_tipo          in (3,4)
                                          and de.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( de.empresa_id
                                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                               , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 63;
            --
            delete from LOG_DET_EXP_COM_IG
             where detexpcomig_id in ( select id
                                         from det_exp_com_ig de
                                        where de.empresa_id       = nvl(en_empresa_id, de.empresa_id)
                                          and de.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                          and de.dm_tipo          in (3,4)
                                          and de.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( de.empresa_id
                                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                               , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 64;
            --
            delete from det_exp_com_ig
             where id in ( select id
                             from det_exp_com_ig de
                            where de.empresa_id       = nvl(en_empresa_id, de.empresa_id)
                              and de.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and de.dm_tipo          in (3,4)
                              and de.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( de.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - det_exp_com_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '15' then
      --
      -- Comércio Eletrônico - Demonstr. do Imposto de Renda e CSLL Retidos na Fonte Y570
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Demonstr. do Imposto de Renda e CSLL Retidos na Fonte Y570'
                                  );
         --
         vn_fase := 65;
         --
         begin
            --
            vn_fase := 66;
            --
            delete from r_loteintws_dicrfig
             where demircsllrfig_id in ( select id
                                           from dem_ir_csll_rf_ig di
                                          where di.empresa_id       = nvl(en_empresa_id, di.empresa_id)
                                            and di.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and di.dm_tipo          in (3,4)
                                            and di.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( di.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 67;
            --
            delete from LOG_DEM_IR_CSLL_RF_IG
             where demircsllrfig_id in ( select id
                                           from dem_ir_csll_rf_ig di
                                          where di.empresa_id       = nvl(en_empresa_id, di.empresa_id)
                                            and di.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and di.dm_tipo          in (3,4)
                                            and di.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( di.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 68;
            --
            delete from dem_ir_csll_rf_ig
             where id in ( select id
                             from dem_ir_csll_rf_ig di
                            where di.empresa_id       = nvl(en_empresa_id, di.empresa_id)
                              and di.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and di.dm_tipo          in (3,4)
                              and di.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( di.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - dem_ir_csll_rf_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '16' then
      --
      -- Comércio Eletrônico - Doações a Campanhas Eleitorais Y580
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Doações a Campanhas Eleitorais Y580'
                                  );
         --
         vn_fase := 69;
         --
         begin
            --
            vn_fase := 70;
            --
            delete from r_loteintws_dceig
             where doaccampeleitig_id in ( select id
                             from doac_camp_eleit_ig dc
                            where dc.empresa_id       = nvl(en_empresa_id, dc.empresa_id)
                              and dc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dc.dm_tipo          in (3,4)
                              and dc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            vn_fase := 71;
            --
            delete from LOG_DOAC_CAMP_ELEIT_IG
             where doaccampeleitig_id in ( select id
                             from doac_camp_eleit_ig dc
                            where dc.empresa_id       = nvl(en_empresa_id, dc.empresa_id)
                              and dc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dc.dm_tipo          in (3,4)
                              and dc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 72;
            --
            delete from doac_camp_eleit_ig
             where id in ( select id
                             from doac_camp_eleit_ig dc
                            where dc.empresa_id       = nvl(en_empresa_id, dc.empresa_id)
                              and dc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dc.dm_tipo          in (3,4)
                              and dc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - doac_camp_eleit_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '17' then
      --
      -- Comércio Eletrônico - Ativos no Exterior Y590
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Ativos no Exterior Y590'
                                  );
         --
         vn_fase := 73;
         --
         begin
            --
            vn_fase := 74;
            --
            delete from r_loteintws_aeig
             where ativoexteriorig_id in ( select id
                             from ativo_exterior_ig ae
                            where ae.empresa_id       = nvl(en_empresa_id, ae.empresa_id)
                              and ae.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ae.dm_tipo          in (3,4)
                              and ae.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ae.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 75;
            --
            delete from LOG_ATIVO_EXTERIOR_IG
             where ativoexteriorig_id in ( select id
                             from ativo_exterior_ig ae
                            where ae.empresa_id       = nvl(en_empresa_id, ae.empresa_id)
                              and ae.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ae.dm_tipo          in (3,4)
                              and ae.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ae.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 76;
            --
            delete from ativo_exterior_ig
             where id in ( select id
                             from ativo_exterior_ig ae
                            where ae.empresa_id       = nvl(en_empresa_id, ae.empresa_id)
                              and ae.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ae.dm_tipo          in (3,4)
                              and ae.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ae.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - ativo_exterior_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '18' then
      --
      -- Comércio Eletrônico - Identificação de Sócios ou Titular Y600
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Identificação de Sócios ou Titular Y600'
                                  );
         --
         vn_fase := 77;
         --
         begin
            --
            vn_fase := 78;
            --
            delete from r_loteintws_isig
             where identsocioig_id in ( select id
                             from ident_socio_ig ids
                            where ids.empresa_id       = nvl(en_empresa_id, ids.empresa_id)
                              and ids.DT_ALT_SOC       between ed_dt_ini and ed_dt_fin
                              and ids.DT_ALT_SOC          > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ids.empresa_id
                                                                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                    , (ed_dt_ini - 1)));
            --
            vn_fase := 79;
            --
            delete from LOG_IDENT_SOCIO_IG
             where identsocioig_id in ( select id
                             from ident_socio_ig ids
                            where ids.empresa_id       = nvl(en_empresa_id, ids.empresa_id)
                              and ids.DT_ALT_SOC       between ed_dt_ini and ed_dt_fin
                              and ids.DT_ALT_SOC          > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ids.empresa_id
                                                                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                    , (ed_dt_ini - 1)));
            --
            vn_fase := 80;
            --
            delete from ident_socio_ig
             where id in ( select id
                             from ident_socio_ig ids
                            where ids.empresa_id       = nvl(en_empresa_id, ids.empresa_id)
                              and ids.DT_ALT_SOC       between ed_dt_ini and ed_dt_fin
                              and ids.DT_ALT_SOC          > nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ids.empresa_id
                                                                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                    , (ed_dt_ini - 1)));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - ident_socio_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '19' then
      --
      -- Comércio Eletrônico - Rendimentos de Dirig. e Conselheiros-Imunes ou Isentas Y612
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Rendimentos de Dirig. e Conselheiros-Imunes ou Isentas Y612'
                                  );
         --
         vn_fase := 81;
         --
         begin
            --
            vn_fase := 82;
            --
            delete from r_loteintws_rdiiig
             where renddirigiiig_id in ( select id
                             from rend_dirig_ii_ig rd
                            where rd.empresa_id       = nvl(en_empresa_id, rd.empresa_id)
                              and rd.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rd.dm_tipo          in (3,4)
                              and rd.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rd.empresa_id
                                                                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                    , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 83;
            --
            delete from LOG_REND_DIRIG_II_IG
             where renddirigiiig_id in ( select id
                             from rend_dirig_ii_ig rd
                            where rd.empresa_id       = nvl(en_empresa_id, rd.empresa_id)
                              and rd.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rd.dm_tipo          in (3,4)
                              and rd.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rd.empresa_id
                                                                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                    , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 84;
            --
            delete from rend_dirig_ii_ig
             where id in ( select id
                             from rend_dirig_ii_ig rd
                            where rd.empresa_id       = nvl(en_empresa_id, rd.empresa_id)
                              and rd.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and rd.dm_tipo          in (3,4)
                              and rd.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rd.empresa_id
                                                                                                                    , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                    , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - rend_dirig_ii_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '20' then
      --
      -- Comércio Eletrônico - Participações Avaliadas Pelo Mét. de Equivalência Patr. Y620
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Participações Avaliadas Pelo Mét. de Equivalência Patr. Y620'
                                  );
         --
         vn_fase := 85;
         --
         begin
            --
            vn_fase := 86;
            --
            delete from r_loteintws_pameqpig
             where partavameteqpatrig_id in ( select id
                                                 from part_ava_met_eq_patr_ig pa
                                                where pa.empresa_id       = nvl(en_empresa_id, pa.empresa_id)
                                                  and pa.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                                  and pa.dm_tipo          in (3,4)
                                                  and pa.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pa.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 87;
            --
            delete from LOG_PART_AVA_MET_EQ_PATR_IG
             where partavameteqpatrig_id in ( select id
                                                 from part_ava_met_eq_patr_ig pa
                                                where pa.empresa_id       = nvl(en_empresa_id, pa.empresa_id)
                                                  and pa.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                                  and pa.dm_tipo          in (3,4)
                                                  and pa.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pa.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 88;
            --
            delete from part_ava_met_eq_patr_ig
             where id in ( select id
                             from part_ava_met_eq_patr_ig pa
                            where pa.empresa_id       = nvl(en_empresa_id, pa.empresa_id)
                              and pa.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and pa.dm_tipo          in (3,4)
                              and pa.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pa.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - part_ava_met_eq_patr_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '21' then
      --
      -- Comércio Eletrônico - Fundos/Clubes de Investimento Y630
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Fundos/Clubes de Investimento Y630'
                                  );
         --
         vn_fase := 89;
         --
         begin
            --
            vn_fase := 90;
            --
            delete from r_loteintws_fiig
             where fundoinvestig_id in ( select id
                             from fundo_invest_ig fi
                            where fi.empresa_id       = nvl(en_empresa_id, fi.empresa_id)
                              and fi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and fi.dm_tipo          in (3,4)
                              and fi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( fi.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 91;
            --
            delete from LOG_FUNDO_INVEST_IG
             where fundoinvestig_id in ( select id
                             from fundo_invest_ig fi
                            where fi.empresa_id       = nvl(en_empresa_id, fi.empresa_id)
                              and fi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and fi.dm_tipo          in (3,4)
                              and fi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( fi.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 92;
            --
            delete from fundo_invest_ig
             where id in ( select id
                             from fundo_invest_ig fi
                            where fi.empresa_id       = nvl(en_empresa_id, fi.empresa_id)
                              and fi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and fi.dm_tipo          in (3,4)
                              and fi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( fi.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - fundo_invest_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '22' then
      --
      -- Comércio Eletrônico - Participações em Consórcios de Empresas Y640
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Participações em Consórcios de Empresas Y640'
                                  );
         --
         vn_fase := 93;
         --
         begin
            --
            vn_fase := 94;
            --
            delete from det_part_cons_empr_ig
             where partconsemprig_id in ( select id
                                            from part_cons_empr_ig pc
                                           where pc.empresa_id       = nvl(en_empresa_id, pc.empresa_id)
                                             and pc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                             and pc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 95;
            --
            delete from r_loteintws_pceig
             where partconsemprig_id in ( select id
                                           from part_cons_empr_ig pc
                                          where pc.empresa_id       = nvl(en_empresa_id, pc.empresa_id)
                                            and pc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and pc.dm_tipo          in (3,4)
                                            and pc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 96;
            --
            delete from LOG_PART_CONS_EMPR_IG
             where partconsemprig_id in ( select id
                                           from part_cons_empr_ig pc
                                          where pc.empresa_id       = nvl(en_empresa_id, pc.empresa_id)
                                            and pc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and pc.dm_tipo          in (3,4)
                                            and pc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 97;
            --
            delete from part_cons_empr_ig
             where id in ( select id
                             from part_cons_empr_ig pc
                            where pc.empresa_id       = nvl(en_empresa_id, pc.empresa_id)
                              and pc.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and pc.dm_tipo          in (3,4)
                              and pc.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( pc.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - part_cons_empr_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '23' then
      --
      -- Comércio Eletrônico - Dados de Sucessoras Y660
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Dados de Sucessoras Y660'
                                  );
         --
         vn_fase := 98;
         --
         begin
            --
            vn_fase := 99;
            --
            delete from r_loteintws_dsig
             where dadosucessoraig_id in ( select id
                             from dado_sucessora_ig ds
                            where ds.empresa_id       = nvl(en_empresa_id, ds.empresa_id)
                              and ds.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ds.dm_tipo          in (3,4)
                              and ds.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ds.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 100;
            --
            delete from LOG_DADO_SUCESSORA_IG
             where dadosucessoraig_id in ( select id
                             from dado_sucessora_ig ds
                            where ds.empresa_id       = nvl(en_empresa_id, ds.empresa_id)
                              and ds.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ds.dm_tipo          in (3,4)
                              and ds.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ds.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 101;
            --
            delete from dado_sucessora_ig
             where id in ( select id
                             from dado_sucessora_ig ds
                            where ds.empresa_id       = nvl(en_empresa_id, ds.empresa_id)
                              and ds.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ds.dm_tipo          in (3,4)
                              and ds.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ds.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - dado_sucessora_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '24' then
      --
      -- Comércio Eletrônico - Demonstrativo das Diferenças na Adoção Inicial Y665
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Demonstrativo das Diferenças na Adoção Inicial Y665'
                                  );
         --
         vn_fase := 102;
         --
         begin
            --
            vn_fase := 103;
            --
            delete from r_loteintws_ddaiig
             where demdifadiniig_id in ( select id
                                           from dem_dif_ad_ini_ig dd
                                          where dd.empresa_id       = nvl(en_empresa_id, dd.empresa_id)
                                            and dd.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and dd.dm_tipo          in (3,4)
                                            and dd.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 104;
            --
            delete from LOG_DEM_DIF_AD_INI_IG
             where demdifadiniig_id in ( select id
                                           from dem_dif_ad_ini_ig dd
                                          where dd.empresa_id       = nvl(en_empresa_id, dd.empresa_id)
                                            and dd.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and dd.dm_tipo          in (3,4)
                                            and dd.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 105;
            --
            delete from dem_dif_ad_ini_ig
             where id in ( select id
                             from dem_dif_ad_ini_ig dd
                            where dd.empresa_id       = nvl(en_empresa_id, dd.empresa_id)
                              and dd.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and dd.dm_tipo          in (3,4)
                              and dd.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( dd.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - dem_dif_ad_ini_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '25' then
      --
      -- Comércio Eletrônico - Outras Informações (Lucro Real) Y671
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Outras Informações (Lucro Real) Y671'
                                  );
         --
         vn_fase := 106;
         --
         begin
            --
            vn_fase := 107;
            --
            delete from r_loteintws_oilrig
             where outrainflrig_id in ( select id
                                           from outra_inf_lr_ig oi
                                          where oi.empresa_id       = nvl(en_empresa_id, oi.empresa_id)
                                            and oi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and oi.dm_tipo          in (3,4)
                                            and oi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oi.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 108;
            --
            delete from LOG_OUTRA_INF_LR_IG
             where outrainflrig_id in ( select id
                                           from outra_inf_lr_ig oi
                                          where oi.empresa_id       = nvl(en_empresa_id, oi.empresa_id)
                                            and oi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and oi.dm_tipo          in (3,4)
                                            and oi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oi.empresa_id
                                                                                                                                 , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                 , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 109;
            --
            delete from outra_inf_lr_ig
             where id in ( select id
                             from outra_inf_lr_ig oi
                            where oi.empresa_id       = nvl(en_empresa_id, oi.empresa_id)
                              and oi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oi.dm_tipo          in (3,4)
                              and oi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oi.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - outra_inf_lr_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '26' then
      --
      -- Comércio Eletrônico - Outras Informações (Lucro Presumido ou Lucro Arbitrado) Y672
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Outras Informações (Lucro Presumido ou Lucro Arbitrado) Y672'
                                  );
         --
         vn_fase := 110;
         --
         begin
            --
            vn_fase := 111;
            --
            delete from r_loteintws_oilplaig
             where outrainflplaig_id in ( select id
                                             from outra_inf_lp_la_ig oi
                                            where oi.empresa_id       = nvl(en_empresa_id, oi.empresa_id)
                                              and oi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and oi.dm_tipo          in (3,4)
                                              and oi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oi.empresa_id
                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 112;
            --
            delete from LOG_OUTRA_INF_LP_LA_IG
             where outrainflplaig_id in ( select id
                                             from outra_inf_lp_la_ig oi
                                            where oi.empresa_id       = nvl(en_empresa_id, oi.empresa_id)
                                              and oi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and oi.dm_tipo          in (3,4)
                                              and oi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oi.empresa_id
                                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 113;
            --
            delete from outra_inf_lp_la_ig
             where id in ( select id
                             from outra_inf_lp_la_ig oi
                            where oi.empresa_id       = nvl(en_empresa_id, oi.empresa_id)
                              and oi.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and oi.dm_tipo          in (3,4)
                              and oi.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( oi.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - outra_inf_lp_la_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '27' then
      --
      -- Comércio Eletrônico - Optantes pelo Paes - Y690
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Optantes pelo Paes - Y690'
                                  );
         --
         vn_fase := 114;
         --
         begin
            --
            vn_fase := 115;
            --
            delete from r_loteintws_iopig
             where infooptpaesig_id in ( select io.id
                                           from info_opt_paes_ig io
                                              , abertura_ecf     ae
                                          where ae.empresa_id       = nvl(en_empresa_id, ae.empresa_id)
                                            and ae.dt_ini           >= ed_dt_ini
                                            and ae.dt_fin           <= ed_dt_fin
                                            and ae.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ae.empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1)));
            --
            vn_fase := 116;
            --
            delete from LOG_INFO_OPT_PAES_IG
             where infooptpaesig_id in ( select io.id
                                           from info_opt_paes_ig io
                                              , abertura_ecf     ae
                                          where ae.empresa_id       = nvl(en_empresa_id, ae.empresa_id)
                                            and ae.dt_ini           >= ed_dt_ini
                                            and ae.dt_fin           <= ed_dt_fin
                                            and ae.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ae.empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1)));
            --
            vn_fase := 117;
            --
            delete from info_opt_paes_ig
             where id in ( select io.id
                             from info_opt_paes_ig io
                                , abertura_ecf     ae
                            where ae.empresa_id       = nvl(en_empresa_id, ae.empresa_id)
                              and ae.dt_ini           >= ed_dt_ini
                              and ae.dt_fin           <= ed_dt_fin
                              and ae.dt_ini           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ae.empresa_id
                                                                                                               , vn_objintegr_id ) -- en_objintegr_id
                                                                                                               , (ed_dt_ini - 1)));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - outra_inf_lp_la_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '28' then
      --
      -- Tabela de Informações de Períodos Anteriore - Y720
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Tabela de Informações de Períodos Anteriore - Y720'
                                  );
         --
         vn_fase := 118;
         --
         begin
            --
            vn_fase := 119;
            --
            delete from r_loteintws_ipaig
             where infperantig_id in ( select id
                             from inf_per_ant_ig ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 120;
            --
            delete from LOG_INF_PER_ANT_IG
             where infperantig_id in ( select id
                             from inf_per_ant_ig ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 121;
            --
            delete from inf_per_ant_ig
             where id in ( select id
                             from inf_per_ant_ig ip
                            where ip.empresa_id       = nvl(en_empresa_id, ip.empresa_id)
                              and ip.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and ip.dm_tipo          in (3,4)
                              and ip.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( ip.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - inf_per_ant_ig - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '29' then
      --
      -- Observações Adicionais - Inf. sobre Grupo Mult. Ent. Decl. - Decl. País-a-País W100
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Inf. sobre Grupo Mult. Ent. Decl. - Decl. País-a-País W100'
                                  );
         --
         vn_fase := 122;
         --
         begin
            --
            vn_fase := 123;
            --
            delete from decl_pais_a_pais_ent_integr
             where declpaisapais_id in ( select dp.id
                                           from inf_mult_decl_pais im
                                              , decl_pais_a_pais   dp
                                          where im.empresa_id         = nvl(en_empresa_id, im.empresa_id)
                                            and dp.infmultdeclpais_id = im.id
                                            and im.ano_ref            = to_number(to_char(ed_dt_ini,'yyyy'))
                                            and im.ano_ref            >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( im.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 124;
            --
            delete from r_loteintws_imdp
             where infmultdeclpais_id in ( select id
                                             from inf_mult_decl_pais im
                                            where im.empresa_id       = nvl(en_empresa_id, im.empresa_id)
                                              and im.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and im.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( im.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 125;
            --
            delete from decl_pais_a_pais
             where infmultdeclpais_id in ( select id
                                             from inf_mult_decl_pais im
                                            where im.empresa_id       = nvl(en_empresa_id, im.empresa_id)
                                              and im.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                                              and im.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( im.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
            vn_fase := 126;
            --
            delete from inf_mult_decl_pais
             where id in ( select id
                             from inf_mult_decl_pais im
                            where im.empresa_id       = nvl(en_empresa_id, im.empresa_id)
                              and im.ano_ref          = to_number(to_char(ed_dt_ini,'yyyy'))
                              and im.ano_ref          >  to_number(to_char(nvl(pk_csf.fkg_recup_dtult_fecha_empresa( im.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)),'yyyy')));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - inf_mult_decl_pais - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   elsif gv_cd_tipo_obj_integr = '30' then
      --
      -- Observações Adicionais - Declaração País-a-País W300
      if nvl(vn_multorg_id, 0) > 0
         or nvl(vn_empresa_id, 0) > 0 then
         --
         -- Registra log
         pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                                  , en_usuario_id => en_usuario_id
                                  , ed_dt_ini     => ed_dt_ini
                                  , ed_dt_fin     => ed_dt_fin
                                  , ev_texto      => 'Integração das Tabelas Dinâmicas do ECF - Observações Adicionais - Declaração País-a-País W300'
                                  );
         --
         vn_fase := 127;
         --
         begin
            --
            vn_fase := 128;
            --
            delete from r_loteintws_dpapoa
             where declpaisapaisobsadic_id in ( select id
                                              from decl_pais_a_pais_obs_adic im
                                             where im.empresa_id       = nvl(en_empresa_id, im.empresa_id)
                                               and im.DT_REF           between ed_dt_ini and ed_dt_fin
                                               and im.DT_REF           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( im.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)));
            --
            vn_fase := 129;
            --
            delete from decl_pais_a_pais_obs_adic
             where id in ( select id
                             from decl_pais_a_pais_obs_adic im
                            where im.empresa_id       = nvl(en_empresa_id, im.empresa_id)
                              and im.DT_REF           between ed_dt_ini and ed_dt_fin
                              and im.DT_REF           >  nvl(pk_csf.fkg_recup_dtult_fecha_empresa( im.empresa_id
                                                                                                                   , vn_objintegr_id ) -- en_objintegr_id
                                                                                                                   , (ed_dt_ini - 1)));
            --
         exception
            when others then
               raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_dados_secf - decl_pais_a_pais_obs_adic - fase ('||vn_fase||'): '||sqlerrm);
         end;
         --
         commit;
         --
         -- Garante que apenas o tipo de objeto em questão seja desprocessado.
         vn_multorg_id := -1;
         vn_empresa_id := -1;
         --
      end if;
      --
   end if;
   --
   <<sair_proc>>
   --
   null;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a informação de exportação. Verifique (pk_despr_integr.pkb_despr_dados_secf): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_dados_secf fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_dados_secf;

------------------------------------------------------------------------------------------
-- Procedimento de Desprocessamento do EFD-REINF
------------------------------------------------------------------------------------------
procedure pkb_despr_reinf ( en_empresa_id in empresa.id%type
                          , en_usuario_id in neo_usuario.id%type
                          , ed_dt_ini     in date
                          , ed_dt_fin     in date
                          )
is
   --
   vn_fase                number := null;
   vn_multorg_id          mult_org.id%type;
   vn_loggenerico_id      log_generico.id%type;
   vn_objintegr_id        obj_integr.id%type;
   vd_dt_ult_fecha        fecha_fiscal_empresa.dt_ult_fecha%type;
   --
   vn_existe              number;
   --
   cursor c_rreceb ( en_multorg_id mult_org.id%type ) is
   select rr.id recrecebassdesp_id
        , rr.empresa_id
        , rr.dt_ref
     from rec_receb_ass_desp rr
        , empresa e
        , usuario_empresa ue
    where rr.dt_ref between ed_dt_ini and ed_dt_fin
      and rr.empresa_id = nvl(en_empresa_id,rr.empresa_id)
      and e.id = rr.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
   cursor c_rrep ( en_multorg_id mult_org.id%type ) is
   select rr.id recrepassdesp_id
        , rr.empresa_id
        , rr.dt_ref
     from rec_rep_ass_desp rr
        , empresa e
        , usuario_empresa ue
    where rr.dt_ref between ed_dt_ini and ed_dt_fin
      and rr.empresa_id = nvl(en_empresa_id,rr.empresa_id)
      and e.id = rr.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
   cursor c_comer ( en_multorg_id mult_org.id%type ) is
   select cp.id comerprodruralpjagr_id
        , cp.empresa_id
        , cp.dt_ref
     from comer_prod_rural_pj_agr cp
        , empresa e
        , usuario_empresa ue
    where cp.dt_ref between ed_dt_ini and ed_dt_fin
      and cp.empresa_id = nvl(en_empresa_id,cp.empresa_id)
      and e.id = cp.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
   cursor c_rec ( en_multorg_id mult_org.id%type ) is
   select re.id recespdesport_id
        , re.empresa_id
        , re.dt_ref
     from rec_esp_desport re
        , empresa e
        , usuario_empresa ue
    where re.dt_ref between ed_dt_ini and ed_dt_fin
      and re.empresa_id = nvl(en_empresa_id,re.empresa_id)
      and e.id = re.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
begin
   --

   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Escrituração Fiscal Digital de Retenções e Outras Informações Fiscais - EFD-REINF.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '55' ); -- infexp
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      if trim(gv_cd_tipo_obj_integr) = '1' then
         --
         vn_fase := 5;
         --
         for rec in c_rreceb (vn_multorg_id) loop
            exit when c_rreceb%notfound or (c_rreceb%notfound) is null;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_ref > vd_dt_ult_fecha then
               --
               -- Verifica se o evento ja está relacionado com algum LOTE para ser enviado
               vn_existe := null;
               --
               begin
                  --
                  select count(1)
                    into vn_existe
                    from rec_receb_ass_desp rr
                       , r_efdreinfr2030_recreceb re
                       , efd_reinf_r2030     er
                   where rr.id       = rec.recrecebassdesp_id
                     and re.recrecebassdesp_id = rr.id
                     and re.efdreinfr2030_id = re.id;
                  --
               exception
                  when others then
                     --
                     vn_existe := null;
                     --
               end;
               --
               vn_fase := 4.1;
               --
               if nvl(vn_existe, 0) = 0 then
                  --
                  delete from csf_own.inf_proc_adm_rec_receb
                   where recrecebassdesp_id = rec.recrecebassdesp_id;
                  --
                  vn_fase := 5;
                  --
                  delete from csf_own.inf_rec_receb_ass_desp
                   where recrecebassdesp_id = rec.recrecebassdesp_id;
                  --
                  vn_fase := 6;
                  --
                  delete from csf_own.R_LOTEINTWS_RRAD
                   where recrecebassdesp_id = rec.recrecebassdesp_id;
                  --
                  vn_fase := 14.3;
                  --
                  delete from csf_own.REC_RECEB_ASS_DESP
                   where id = rec.recrecebassdesp_id;
                  --
               else
                  --
                  vv_resumo := 'Registro de Recursos Recebidos ja relacionado com algum Lote de Evento.';
                  --
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => vv_resumo
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => 1
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   , en_dm_impressa    => 1
                                                   );
                  --
               end if;
               --
            else
               --
               vn_fase := 9;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar Recursos de Recebidos por Associação Desportiva não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                , en_dm_impressa    => 1
                                                );
               --
            end if;
            --
         end loop;
         --
      elsif trim(gv_cd_tipo_obj_integr) = '2' then
         --
         vn_fase := 10;
         --
         for rec in c_rrep (vn_multorg_id) loop
           exit when c_rrep%notfound or (c_rrep%notfound) is null;
            --
            vn_fase := 11;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            vn_fase := 12;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_ref > vd_dt_ult_fecha then
               --
               -- Verifica se o evento ja está relacionado com algum LOTE para ser enviado
               vn_existe := null;
               --
               begin
                  --
                  select count(1)
                    into vn_existe
                    from rec_rep_ass_desp rr
                       , efd_reinf_r2040     er
                       , r_efdreinfr2040_recrep re
                   where rr.id       = rec.recrepassdesp_id
                     and re.recrepassdesp_id = rr.id
                     and re.efdreinfr2040_id = er.id;
                  --
               exception
                  when others then
                     --
                     vn_existe := null;
                     --
               end;
               --
               vn_fase := 13;
               --
               if nvl(vn_existe, 0) = 0 then
                  --
                  vn_fase := 14;
                  --
                  delete from csf_own.inf_proc_adm_rec_rep
                   where recrepassdesp_id = rec.recrepassdesp_id;
                  --
                  vn_fase := 14.1;
                  --
                  delete from csf_own.INF_REC_REP_ASS_DESP
                   where recrepassdesp_id = rec.recrepassdesp_id;
                  --
                  vn_fase := 14.2;
                  --
                  delete from csf_own.R_LOTEINTWS_RRPAD
                   where recrepassdesp_id = rec.recrepassdesp_id;
                  --
                  vn_fase := 14.3;
                  --
                  delete from csf_own.REC_REP_ASS_DESP
                   where id = rec.recrepassdesp_id;
                  --
               else
                  --
                  vv_resumo := 'Registro de Recurso Repassado para associação Desportiva ja relacionado com algum Lote de Evento.';
                  --
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => vv_resumo
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => 1
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   , en_dm_impressa    => 1
                                                   );
                  --
               end if;
               --
            else
               --
               vn_fase := 9;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar Recursos de Repassado para Associação Desportiva não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                , en_dm_impressa    => 1
                                                );
               --
            end if;
            --
         end loop;
         --
      elsif trim(gv_cd_tipo_obj_integr) = '3' then
         --
         vn_fase := 10;
         --
         for rec in c_comer (vn_multorg_id) loop
           exit when c_comer%notfound or (c_comer%notfound) is null;
            --
            vn_fase := 11;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            vn_fase := 12;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_ref > vd_dt_ult_fecha then
               --
               -- Verifica se o evento ja está relacionado com algum LOTE para ser enviado
               vn_existe := null;
               --
               begin
                  --
                  select count(1)
                    into vn_existe
                    from comer_prod_rural_pj_agr rr
                       , efd_reinf_r2050     er
                   where rr.id       = rec.comerprodruralpjagr_id
                     and er.comerprodruralpjagr_id = rr.id;
                  --
               exception
                  when others then
                     --
                     vn_existe := null;
                     --
               end;
               --
               vn_fase := 12.1;
               --
               if nvl(vn_existe, 0) = 0 then
                  --
                  delete from csf_own.COMER_PROD_INF_PROC_ADM
                   where tipocomerprodrural_id in ( select id
                                                      from tipo_comer_prod_rural
                                                     where comerprodruralpjagr_id = rec.comerprodruralpjagr_id );
                  --
                  vn_fase := 13;
                  --
                  delete from csf_own.TIPO_COMER_PROD_RURAL_NF
                   where tipocomerprodrural_id in ( select id
                                                      from tipo_comer_prod_rural
                                                     where comerprodruralpjagr_id = rec.comerprodruralpjagr_id );
                  --
                  delete from csf_own.TIPO_COMER_PROD_RURAL
                   where comerprodruralpjagr_id = rec.comerprodruralpjagr_id;
                  --
                  vn_fase := 14;
                  --
                  delete from csf_own.R_LOTEINTWS_CPRPJA
                   where comerprodruralpjagr_id = rec.comerprodruralpjagr_id;
                  --
                  vn_fase := 14.2;
                  --
                  delete from csf_own.comer_prod_rural_pj_agr
                   where id = rec.comerprodruralpjagr_id;
                  --
               else
                  --
                  vv_resumo := 'Registro de Comercialização de Produtor Rural de Nota Fiscal ja relacionado com algum Lote de Evento.';
                  --
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => vv_resumo
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => 1
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   , en_dm_impressa    => 1
                                                   );
                  --
               end if;
               --
            else
               --
               vn_fase := 15;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar Recursos de Recebidos por Associação Desportiva não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                , en_dm_impressa    => 1
                                                );
               --
            end if;
            --
         end loop;
         --
      elsif trim(gv_cd_tipo_obj_integr) = '4' then
         --
         vn_fase := 16;
         --
         for rec in c_rec (vn_multorg_id) loop
           exit when c_rec%notfound or (c_rec%notfound) is null;
            --
            vn_fase := 17;
            --
            if nvl(en_empresa_id,0) = 0 then
               --
               vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                          , vn_objintegr_id ) -- en_objintegr_id
                                                                          , (ed_dt_ini - 1));
               --
            end if;
            --
            vn_fase := 18;
            --
            if vd_dt_ult_fecha is null or
               rec.dt_ref > vd_dt_ult_fecha then
               --
               -- Verifica se o evento ja está relacionado com algum LOTE para ser enviado
               vn_existe := null;
               --
               begin
                  --
                  select count(1)
                    into vn_existe
                    from rec_esp_desport rr
                       , efd_reinf_r3010     er
                       , efd_reinf_r3010_det det
                   where rr.id       = rec.recespdesport_id
                     and det.recespdesport_id = rr.id
                     and det.efdreinfr3010_id = er.id;
                  --
               exception
                  when others then
                     --
                     vn_existe := null;
                     --
               end;
               --
               vn_fase := 18;
               --
               if nvl(vn_existe,0) = 0 then
                  --
                  delete from csf_own.INF_PROC_ADM_REC_ESP
                   where recespdesporttotal_id in ( select id
                                                      from rec_esp_desport_total
                                                     where recespdesport_id = rec.recespdesport_id);
                  --
                  vn_fase := 18.2;
                  --
                  delete from csf_own.REC_ESP_DESPORT_TOTAL
                   where recespdesport_id = rec.recespdesport_id;
                  --
                  vn_fase := 18.3;
                  --
                  delete from csf_own.R_LOTEINTWS_RED
                   where recespdesport_id = rec.recespdesport_id;
                  --
                  vn_fase := 18.4;
                  --
                  delete from csf_own.REC_ESP_DESPORT
                   where id = rec.recespdesport_id;
                  --
               else
                  --
                  vv_resumo := 'Registro de Recursos de Espetáculos Desportivo ja relacionado com algum Lote de Evento.';
                  --
                  pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                   , ev_mensagem       => 'Desprocessar Integração'
                                                   , ev_resumo         => vv_resumo
                                                   , en_tipo_log       => informacao
                                                   , en_referencia_id  => 1
                                                   , ev_obj_referencia => 'DESPR_INTEGR'
                                                   , en_empresa_id     => gn_empresa_id
                                                   , en_dm_impressa    => 1
                                                   );
                  --
               end if;
               --
            else
               --
               vn_fase := 9;
               -- Gerar log no agendamento devido a data de fechamento
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => 'Período informado para desprocessar  não permitido devido a data de '||
                                                                       'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                                , en_tipo_log       => info_fechamento
                                                , en_referencia_id  => null
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                , en_dm_impressa    => 1
                                                );
               --
            end if;
            --
         end loop;
         --
      end if;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a informação de exportação. Verifique (pk_despr_integr.pkb_despr_reinf): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_reinf fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_reinf;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar a informação de exportação
------------------------------------------------------------------------------------------
procedure pkb_despr_infexp ( en_empresa_id in empresa.id%type
                           , en_usuario_id in neo_usuario.id%type
                           , ed_dt_ini     in date
                           , ed_dt_fin     in date
                           )
is
   --
   vn_fase                number := null;
   vn_multorg_id          mult_org.id%type;
   vn_loggenerico_id      log_generico.id%type;
   vn_objintegr_id        obj_integr.id%type;
   vd_dt_ult_fecha        fecha_fiscal_empresa.dt_ult_fecha%type;
   --
   vn_existe              number;
   --
   cursor c_infoexp (en_multorg_id mult_org.id%type) is
   select ie.id
        , ie.empresa_id
        , ie.dt_de   dt_ref
        , ie.dt_avb
     from infor_exportacao ie
        , empresa e
        , usuario_empresa ue
    where ie.dt_avb between ed_dt_ini and ed_dt_fin -- ie.dt_de between ed_dt_ini and ed_dt_fin
      and ie.empresa_id = nvl(en_empresa_id,ie.empresa_id)
      and e.id = ie.empresa_id
      and e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := gn_multorg_id;
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Informações sobre Exportação.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '53' ); -- infexp
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 4;
      --
      for rec in c_infoexp (vn_multorg_id) loop
         exit when c_infoexp%notfound or (c_infoexp%notfound) is null;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                                                       , (ed_dt_ini - 1));
            --
         end if;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_avb > vd_dt_ult_fecha then
            --rec.dt_ref > vd_dt_ult_fecha then
            --
            -- Verifica de a nota contem vínculo com a tabela de detalhe da geração de informações sobre exportação.
            vn_existe := null;
            --
            begin
               --
               select count(1)
                 into vn_existe
                 from infor_export_nota_fiscal ie
                    , det_ger_infor_export     dg
                where ie.inforexportacao_id       = rec.id
                  and dg.inforexportnotafiscal_id = ie.id;
               --
            exception
               when others then
                  --
                  vn_existe := null;
                  --
            end;
            --
            vn_fase := 4.1;
            --
            if nvl(vn_existe, 0) = 0 then
               --
               delete from oper_export_ind_nf oein
                  where inforexportnotafiscal_id in ( select ienf.id
                                                        from infor_export_nota_fiscal ienf
                                                           , infor_exportacao ie
                                                       where ienf.inforexportacao_id = ie.id
                                                         and ie.id = rec.id );
               --
               vn_fase := 5;
               --
               delete from infor_export_nota_fiscal ienf where ienf.inforexportacao_id = rec.id;
               --
               vn_fase := 6;
               --
               delete from r_loteintws_ie where inforexportacao_id = rec.id;
               --
               vn_fase := 7;
               --
               delete from infor_exportacao ie where ie.id = rec.id;
               --
               commit;
               --
            else
               --
               vv_resumo := 'Nota fiscal possui vinculo com o processo de gereção de informação sobre exportação.';
               --
               pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                                , ev_mensagem       => 'Desprocessar Integração'
                                                , ev_resumo         => vv_resumo
                                                , en_tipo_log       => informacao
                                                , en_referencia_id  => 1
                                                , ev_obj_referencia => 'DESPR_INTEGR'
                                                , en_empresa_id     => gn_empresa_id
                                                );
               --
            end if;
            --
         else
            --
            vn_fase := 9;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração de informação de exportacção não permitido devido a data de '||
                                                                    'fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir a informação de exportação. Verifique (pk_despr_integr.pkb_despr_infexp): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_infexp fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_infexp;
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar a informação dos Cadastros Gerais
------------------------------------------------------------------------------------------
procedure pkb_despr_cad_geral ( en_empresa_id in empresa.id%Type
                               , en_usuario_id in neo_usuario.id%type
                               , ed_dt_ini     in date
                               , ed_dt_fin     in date
                               )
is
   --
   PRAGMA             AUTONOMOUS_TRANSACTION;
   vn_fase            number := 0;
   vn_id              inventario.id%type;
   vn_objintegr_id    obj_integr.id%type;
   vd_dt_ult_fecha    fecha_fiscal_empresa.dt_ult_fecha%type;
   vn_loggenerico_id  log_generico.id%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_imob (en_multorg_id mult_org.id%type) is
   select b.id
        , b.empresa_id
        , n.dt_doc
     from empresa     e
        , usuario_empresa ue
        , bem_ativo_imob b-- Cadastros Gerais - Bens do Ativo Imobilizado
        , nf_bem_ativo_imob n
    where e.multorg_id = en_multorg_id
      and ue.empresa_id = e.id
      and ue.usuario_id = en_usuario_id
      and b.empresa_id = nvl(en_empresa_id, b.empresa_id)
      and b.empresa_id = e.id
      and n.bemativoimob_id = b.id
      and trunc(n.dt_doc) between trunc(ed_dt_ini) and trunc(ed_dt_fin) ;
   --
begin
   --
   vn_multorg_id := gn_multorg_id;
   --
   gn_empresa_id := en_empresa_id;
   --
   if nvl(vn_multorg_id,0) > 0
      or nvl(en_empresa_id,0) > 0 then
      --
      vn_fase := 1;
      -- registra o log
      pkb_reg_log_despr_integr ( en_empresa_id => en_empresa_id
                               , en_usuario_id => en_usuario_id
                               , ed_dt_ini     => ed_dt_ini
                               , ed_dt_fin     => ed_dt_fin
                               , ev_texto      => 'Cadastros Gerais.'
                               );
      --
      vn_fase := 2;
      --
      if nvl(gn_objintegr_id,0) = 0 then
         vn_objintegr_id := pk_csf.fkg_recup_objintegr_id( ev_cd => '1' ); -- Cadastros Gerais
      else
         vn_objintegr_id := gn_objintegr_id;
      end if;
      --
      vn_fase := 3;
      --
      if nvl(en_empresa_id,0) > 0 then
         --
         vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id     -- en_empresa_id
                                                                    , vn_objintegr_id ) -- en_objintegr_id
                              , (ed_dt_ini - 1));
         --
         if nvl(vn_multorg_id,0) = 0 then
            --
            vn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
            --
         end if;
         --
      end if;
      --
      vn_fase := 3;
      --
      -- Para Bens do Ativo Imobilizado -  tabela bem_ativo_imob
      for rec in c_imob (vn_multorg_id) loop
         exit when c_imob%notfound or (c_imob%notfound) is null;
         --
         vn_fase := 4;
         --
         if nvl(en_empresa_id,0) = 0 then
            --
            vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa( rec.empresa_id -- en_empresa_id
                                                                       , vn_objintegr_id ) -- en_objintegr_id
                                 , (ed_dt_ini - 1));
            --
         end if;
         --
         vn_fase := 5;
         --
         if vd_dt_ult_fecha is null or
            rec.dt_doc > vd_dt_ult_fecha then
            --
            vn_id := rec.id;
            --
            vn_fase := 6;
            --
            delete from infor_util_bem         where bemativoimob_id  = vn_id;
            --
            vn_fase := 6.1;
            --
            delete from item_calc_pat          where bemativoimob_id  = vn_id;
            --
            vn_fase := 6.2;
            --
            delete from MOV_ATPERM_DOC_FISCAL_ITEM where movatpermdocfiscal_id
            in (select df.id from MOV_ATPERM_DOC_FISCAL df,mov_atperm a where df.movatperm_id = a.id and a.bemativoimob_id  = vn_id );
            --
            vn_fase := 6.3;
            --
            delete from MOV_ATPERM_DOC_FISCAL  where movatperm_id in (select Id from mov_atperm where bemativoimob_id  = vn_id);
            --
            vn_fase := 6.4;
            --
            delete from mov_atperm             where bemativoimob_id  = vn_id;
            --
            vn_fase := 6.5;
            --
            delete from itnf_bem_ativo_imob    where nfbemativoimob_id in (select id from nf_bem_ativo_imob where bemativoimob_id = vn_id);
            --
            vn_fase := 6.6;
            --
            delete from nf_bem_ativo_imob      where bemativoimob_id = vn_id;
            --
            vn_fase := 6.7;
            --
            delete from rec_imp_bem_ativo_imob where bemativoimob_id = vn_id;
            --
            vn_fase := 6.8;
            --
            delete from R_LOTEINTWS_BAI        where bemativoimob_id  = vn_id;
            --
            vn_fase := 6.9;
            --
            delete from bem_ativo_imob         where ar_bemativoimob_id in (select id from bem_ativo_imob where id = vn_id);
            --
            vn_fase := 7;
            --
            delete from bem_ativo_imob          where id = vn_id;
            --
         else
            --
            vn_fase := 8;
            -- Gerar log no agendamento devido a data de fechamento
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => 'Desprocessar Integração'
                                             , ev_resumo         => 'Período informado para desprocessar a integração do inventário não permitido devido a data '||
                                                                    'de fechamento fiscal '||to_char(vd_dt_ult_fecha,'dd/mm/yyyy')||').'
                                             , en_tipo_log       => info_fechamento
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'DESPR_INTEGR'
                                             , en_empresa_id     => gn_empresa_id
                                             );
            --
         end if;
         --
      end loop;
      --
      vn_fase := 9;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      rollback;
      --
      vv_resumo := 'Problemas ao excluir Cadastro Geral (id = '||vn_id||'). Verifique (pk_despr_integr.pkb_despr_cad_geral): '||sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => informacao
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_INTEGR'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_cad_geral fase ('||vn_fase||'): '||sqlerrm);
      --
end pkb_despr_cad_geral;
-- ======================================================================================================================== --
-- procedimento para desprocessamento da análise de conversão anp
-- ======================================================================================================================== --
procedure pkb_despr_analiseconveranp(en_empresa_id in empresa.id%Type
                                   , en_usuario_id in neo_usuario.id%type
                                   , ed_dt_ini     in date
                                   , ed_dt_fin     in date)
is
   --
   vn_fase  number := 0;
   vn_loggenerico_id  Log_Generico.id%TYPE;
   ERRO exception;
   --
begin
   --
   vn_fase := 1;
   --
   BEGIN
       DELETE CSF_OWN.R_LOTEINTWS_ANALCONVANP R
        WHERE R.ANALISECONVERSAOANP_ID IN (SELECT ANP.ID
                                            FROM ANALISE_CONVERSAO_ANP ANP
                                           WHERE ANP.DT_ANALISE BETWEEN ED_DT_INI AND ed_dt_fin
                                             AND ANP.ITEM_ID IN ( SELECT DISTINCT I.ID
                                                                    FROM ANALISE_CONVERSAO_ANP ACA
                                                                       , ITEM I
                                                                   WHERE 1 = 1
                                                                     AND ACA.ITEM_ID = I.ID
                                                                     AND TO_DATE(ACA.DT_ANALISE, 'dd/mm/rrrr') BETWEEN
                                                                         TO_DATE(ED_DT_INI, 'dd/mm/rrrr') AND
                                                                         TO_DATE(ed_dt_fin, 'dd/mm/rrrr')
                                                                     AND I.EMPRESA_ID IN (SELECT E.ID
                                                                                            FROM EMPRESA E
                                                                                           WHERE 1=1
                                                                                             AND E.MULTORG_ID = nvl(GN_MULTORG_ID,E.MULTORG_ID)
                                                                                             AND E.ID         = NVL(EN_EMPRESA_ID,E.ID)
                                                                                         )
                                                                )
                                          );
   EXCEPTION
     WHEN OTHERS THEN
       vv_resumo := 'Erro na PKB_EXCLUIR_ANALISECONVERSAOANP fase(' || vn_fase ||', Dt_ini:'||ed_dt_ini||', Dt_fin:'||ed_dt_fin||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id||'): ' || sqlerrm;
       RAISE ERRO;
   END;
   --
   vn_fase := 2;
   --
   BEGIN
       delete from analise_conversao_anp anp
             where anp.dt_analise between ed_dt_ini and ed_dt_fin
               and anp.item_id in ( SELECT DISTINCT I.ID
                                      FROM ANALISE_CONVERSAO_ANP ACA
                                         , ITEM I
                                     WHERE 1 = 1
                                       AND ACA.ITEM_ID = I.ID
                                       AND TO_DATE(ACA.DT_ANALISE, 'dd/mm/rrrr') BETWEEN
                                           TO_DATE(ED_DT_INI, 'dd/mm/rrrr') AND
                                           TO_DATE(ED_DT_FIn, 'dd/mm/rrrr')
                                       AND I.EMPRESA_ID IN (SELECT E.ID
                                                              FROM EMPRESA E
                                                             WHERE 1=1
                                                               AND E.MULTORG_ID = nvl(gn_multorg_id,E.MULTORG_ID)
                                                               AND E.ID         = NVL(EN_EMPRESA_ID,E.ID)
                                                           )
                                  );
   EXCEPTION
     WHEN OTHERS THEN
       vv_resumo := 'Erro na PKB_EXCLUIR_ANALISECONVERSAOANP fase(' || vn_fase ||', Dt_ini:'||ed_dt_ini||', Dt_fim:'||ed_dt_fin||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id||'): ' || sqlerrm;
       RAISE ERRO;
   END;
   --
   vn_fase := 3;
   --
   commit;
   --
   pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                          , ev_mensagem        => 'Exclução da ANALISE_CONVERSAO_ANP'
                                          , ev_resumo          => 'Período excluído '||ed_dt_ini||', '||ed_dt_fin||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id
                                          , en_tipo_log        => INFORMACAO
                                          , en_referencia_id   => null
                                          , ev_obj_referencia  => 'DESPR_ANALISE_CONVERSÃO' );
   --
exception
   WHEN ERRO THEN
     --
     ROLLBACK;
     --
        begin
           --
           pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                            , ev_mensagem       => 'Desprocessar Integração'
                                            , ev_resumo         => vv_resumo
                                            , en_tipo_log       => erro_de_sistema
                                            , en_referencia_id  => 1
                                            , ev_obj_referencia => 'DESPR_ANALISE_CONVERSÃO'
                                            , en_empresa_id     => gn_empresa_id
                                            , en_dm_impressa    => 1
                                            );
           --
        exception
           when others then
              null;
        end;
   when others then
      --
      vv_resumo := 'Erro na PKB_EXCLUIR_ANALISECONVERSAOANP fase(' || vn_fase ||', Dt_ini:'||ed_dt_ini||', Dt_fim:'||ed_dt_fin||', usuário:'||en_usuario_id||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id||'): ' || sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => erro_de_sistema
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_ANALISE_CONVERSÃO'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
end pkb_despr_analiseconveranp;
--
-- ======================================================================================================================== --
-- procedimento para desprocessamento do movimento de estoque
-- ======================================================================================================================== --
procedure pkb_despr_movto_estq(en_empresa_id in empresa.id%Type
                             , en_usuario_id in neo_usuario.id%type
                             , ed_dt_ini     in date
                             , ed_dt_fin     in date)
is
   --
   vn_fase  number := 0;
   vn_loggenerico_id  Log_Generico.id%TYPE;
   ERRO exception;
   --
begin
   --
   vn_fase := 1;
   --
   BEGIN

       DELETE CSF_OWN.R_LOTEINTWS_MOVTOESTQ R
        WHERE R.MOVTOESTQ_ID IN (SELECT M.ID
                                   FROM CSF_OWN.MOVTO_ESTQ M
                                  WHERE M.DT BETWEEN ED_DT_INI AND ED_DT_FIN
                                    AND M.EMPRESA_ID IN (SELECT E.ID
                                                           FROM EMPRESA E
                                                          WHERE 1=1
                                                            AND E.MULTORG_ID = nvl(GN_MULTORG_ID,E.MULTORG_ID)
                                                            AND E.ID         = NVL(EN_EMPRESA_ID,E.ID)
                                                        )
                                 );

   EXCEPTION
     WHEN OTHERS THEN
       vv_resumo := 'Erro na pkb_despr_movto_estq fase(' || vn_fase ||', Dt_ini:'||ed_dt_ini||', Dt_fin:'||ed_dt_fin||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id||'): ' || sqlerrm;
       RAISE ERRO;
   END;
   --
   vn_fase := 2;
   --
   BEGIN

     DELETE FROM MOVTO_ESTQ M
           WHERE M.DT BETWEEN ED_DT_INI AND ED_DT_FIN
             AND M.EMPRESA_ID IN (SELECT E.ID
                                    FROM EMPRESA E
                                   WHERE 1=1
                                     AND E.MULTORG_ID = nvl(GN_MULTORG_ID,E.MULTORG_ID)
                                     AND E.ID         = NVL(EN_EMPRESA_ID,E.ID)
                                 );
   EXCEPTION
     WHEN OTHERS THEN
       vv_resumo := 'Erro na pkb_despr_movto_estq fase(' || vn_fase ||', Dt_ini:'||ed_dt_ini||', Dt_fim:'||ed_dt_fin||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id||'): ' || sqlerrm;
       RAISE ERRO;
   END;
   --
   vn_fase := 3;
   --
   commit;
   --
   pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                          , ev_mensagem        => 'Exclução do Movimento de Estoque'
                                          , ev_resumo          => 'Período excluído '||ed_dt_ini||', '||ed_dt_fin||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id
                                          , en_tipo_log        => INFORMACAO
                                          , en_referencia_id   => null
                                          , ev_obj_referencia  => 'DESPR_MOVTO_ESTQ' );
   --
exception
   WHEN ERRO THEN
     --
     ROLLBACK;
     --
        begin
           --
           pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                            , ev_mensagem       => 'Desprocessar Integração'
                                            , ev_resumo         => vv_resumo
                                            , en_tipo_log       => erro_de_sistema
                                            , en_referencia_id  => 1
                                            , ev_obj_referencia => 'DESPR_MOVTO_ESTQ'
                                            , en_empresa_id     => gn_empresa_id
                                            , en_dm_impressa    => 1
                                            );
           --
        exception
           when others then
              null;
        end;
   when others then
      --
      vv_resumo := 'Erro na PKB_EXCLUIR_ANALISECONVERSAOANP fase(' || vn_fase ||', Dt_ini:'||ed_dt_ini||', Dt_fim:'||ed_dt_fin||', usuário:'||en_usuario_id||', Empresa: '||en_empresa_id ||', usuário: '||en_usuario_id||'): ' || sqlerrm;
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                       , ev_mensagem       => 'Desprocessar Integração'
                                       , ev_resumo         => vv_resumo
                                       , en_tipo_log       => erro_de_sistema
                                       , en_referencia_id  => 1
                                       , ev_obj_referencia => 'DESPR_MOVTO_ESTQ'
                                       , en_empresa_id     => gn_empresa_id
                                       , en_dm_impressa    => 1
                                       );
      --
end pkb_despr_movto_estq;
--
------------------------------------------------------------------------------------------
-- Procedimento para desprocessar o Bloco M
------------------------------------------------------------------------------------------
procedure pkb_despr_m_pc(en_empresa_id in empresa.id%Type,
                         en_usuario_id in neo_usuario.id%type,
                         ed_dt_ini     in date,
                         ed_dt_fin     in date) is
  --
  PRAGMA AUTONOMOUS_TRANSACTION;
  vn_fase           number := 0;
  vn_id             inf_rend_dirf.id%type;
  vn_loggenerico_id log_generico.id%type;
  vd_dt_ult_fecha   fecha_fiscal_empresa.dt_ult_fecha%type;
  vn_multorg_id     mult_org.id%type;
  vn_objintegr_id   obj_integr.id%type;
  --
  cursor c_pis is 
    select p.empresa_id, 
           i.id infadicdifpis_id, 
           p.dt_ini dt_ref
      from per_cons_contr_pis p,
           cons_contr_pis     c,
           det_cons_contr_pis d,
           inf_adic_dif_pis   i
     where p.empresa_id         = en_empresa_id
       and p.dt_ini             = ed_dt_ini
       and p.dt_fin             = ed_dt_fin
       and c.perconscontrpis_id = p.id
       and d.conscontrpis_id    = c.id
       and i.detconscontrpis_id = d.id;
  --
  cursor c_cofins is
    select p.empresa_id, 
           i.id infadicdifcofins_id, 
           p.dt_ini dt_ref
      from per_cons_contr_cofins p,
           cons_contr_cofins     c,
           det_cons_contr_cofins d,
           inf_adic_dif_cofins   i
     where p.empresa_id            = en_empresa_id
       and p.dt_ini                = ed_dt_ini
       and p.dt_fin                = ed_dt_fin
       and c.perconscontrcofins_id = p.id
       and d.conscontrcofins_id    = c.id
       and i.detconscontrcofins_id = d.id;
begin
  --
  vn_fase := 1;
  --
  vn_multorg_id := gn_multorg_id;
  gn_empresa_id := en_empresa_id;
  --
  if nvl(vn_multorg_id, 0) > 0 or nvl(en_empresa_id, 0) > 0 then
    --
    vn_fase := 2;
    --
    -- Registra o log
    pkb_reg_log_despr_integr(en_empresa_id => en_empresa_id,
                             en_usuario_id => en_usuario_id,
                             ed_dt_ini     => ed_dt_ini,
                             ed_dt_fin     => ed_dt_fin,
                             ev_texto      => 'Demais Documentos e Operações - Bloco M EFD Contribuições.');
    --
    vn_fase := 3;
    --
    if nvl(gn_objintegr_id, 0) = 0 then
      --
      vn_objintegr_id := pk_csf.fkg_recup_objintegr_id(ev_cd => '57'); -- Demais Documentos e Operações - Bloco M EFD Contribuições
      --
    else
      --
      vn_objintegr_id := gn_objintegr_id;
      --
    end if;
    --
    vn_fase := 4;
    --
    if nvl(en_empresa_id, 0) > 0 then
      --
      vd_dt_ult_fecha := nvl(pk_csf.fkg_recup_dtult_fecha_empresa(en_empresa_id,
                                                                  vn_objintegr_id), (ed_dt_ini - 1));
      --
      vn_fase := 5;
      --
      if nvl(vn_multorg_id, 0) = 0 then
        --
        vn_multorg_id := pk_csf.fkg_multorg_id_empresa(en_empresa_id => en_empresa_id);
        --
        vn_fase := 6;
        --
      end if;
      --
    end if;
    --
    -- PIS
    for rec in c_pis loop
      exit when c_pis%notfound or(c_pis%notfound) is null;
      --
      if vd_dt_ult_fecha is null or rec.dt_ref > vd_dt_ult_fecha then
        --
        vn_fase := 7;
        --
        begin
          delete 
            from inf_adic_dif_pis i 
           where i.id = rec.infadicdifpis_id;
        exception
          when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_m_pc - inf_adic_dif_pis - fase (' || vn_fase || '): ' || sqlerrm);
        end;
        --
        vn_fase := 8;
        --
        begin
          delete 
            from contr_pis_dif_per_ant c
           where c.empresa_id = en_empresa_id
             and c.dt_ini     = ed_dt_ini
             and c.dt_fin     = ed_dt_fin;
        exception
          when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_m_pc - contr_pis_dif_per_ant - fase (' || vn_fase || '): ' || sqlerrm);
        end;
        --
        -- delete from r_loteintws_ird where infrenddirf_id = rec.id;
        --
      else
        --
        vn_fase := 9;
        --
        -- Gerar log no agendamento devido a data de fechamento
        pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                         ev_mensagem       => 'Desprocessar Integração',
                                         ev_resumo         => 'Período informado para desprocessar a integração de Demais Documentos e Operações - Bloco M EFD Contribuições não ' || 'permitido devido a data de fechamento fiscal ' || to_char(vd_dt_ult_fecha, 'dd/mm/yyyy') || ').',
                                         en_tipo_log       => info_fechamento,
                                         en_referencia_id  => null,
                                         ev_obj_referencia => 'DESPR_INTEGR',
                                         en_empresa_id     => gn_empresa_id);
        --
      end if;
      --
    end loop; -- c_m_pis
    --
    vn_fase := 10;
    --
    if vd_dt_ult_fecha is null or ed_dt_ini > vd_dt_ult_fecha then
      --
      vn_fase := 11;
      --
      begin
        delete 
          from contr_pis_dif_per_ant c
         where c.empresa_id = en_empresa_id
           and c.dt_ini     = ed_dt_ini
           and c.dt_fin     = ed_dt_fin;
      exception
        when others then
          raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_m_pc - contr_pis_dif_per_ant - fase (' || vn_fase || '): ' || sqlerrm);
      end;
      --
      -- delete from r_loteintws_ird where infrenddirf_id = rec.id;
      --
    else
      --
      vn_fase := 12;
      --
      -- Gerar log no agendamento devido a data de fechamento
      pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                       ev_mensagem       => 'Desprocessar Integração',
                                       ev_resumo         => 'Período informado para desprocessar a integração de Demais Documentos e Operações - Bloco M EFD Contribuições não ' || 'permitido devido a data de fechamento fiscal ' || to_char(vd_dt_ult_fecha, 'dd/mm/yyyy') || ').',
                                       en_tipo_log       => info_fechamento,
                                       en_referencia_id  => null,
                                       ev_obj_referencia => 'DESPR_INTEGR',
                                       en_empresa_id     => gn_empresa_id);
      --
    end if;
    --
    vn_fase := 13;
    --
    -- COFINS
    for rec in c_cofins loop
      exit when c_cofins%notfound or(c_cofins%notfound) is null;
      --
      if vd_dt_ult_fecha is null or rec.dt_ref > vd_dt_ult_fecha then
        --
        vn_fase := 14;
        --
        begin
          delete 
            from inf_adic_dif_cofins i
           where i.id = rec.infadicdifcofins_id;
        exception
          when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_m_pc - inf_adic_dif_cofins - fase (' || vn_fase || '): ' || sqlerrm);
        end;
        --
        vn_fase := 15;
        --
        begin
          delete 
            from contr_cofins_dif_per_ant c
           where c.empresa_id = en_empresa_id
             and c.dt_ini     = ed_dt_ini
             and c.dt_fin     = ed_dt_fin;
        exception
          when others then
            raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_m_pc - contr_cofins_dif_per_ant - fase (' || vn_fase || '): ' || sqlerrm);
        end;
        --
      else
        --
        vn_fase := 16;
        --
        -- Gerar log no agendamento devido a data de fechamento
        pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                         ev_mensagem       => 'Desprocessar Integração',
                                         ev_resumo         => 'Período informado para desprocessar a integração de Demais Documentos e Operações - Bloco M EFD Contribuições não ' || 'permitido devido a data de fechamento fiscal ' || to_char(vd_dt_ult_fecha, 'dd/mm/yyyy') || ').',
                                         en_tipo_log       => info_fechamento,
                                         en_referencia_id  => null,
                                         ev_obj_referencia => 'DESPR_INTEGR',
                                         en_empresa_id     => gn_empresa_id);
        --
      end if;
      --
    end loop; -- c_cofins
    --
    vn_fase := 17;
    --
    if vd_dt_ult_fecha is null or ed_dt_ini > vd_dt_ult_fecha then
      --
      vn_fase := 18;
      --
      begin
        delete 
          from contr_cofins_dif_per_ant c
         where c.empresa_id = en_empresa_id
           and c.dt_ini     = ed_dt_ini
           and c.dt_fin     = ed_dt_fin;
      exception
        when others then
          raise_application_error(-20101, 'Problemas em pk_despr_integr.pkb_despr_m_pc - contr_cofins_dif_per_ant - fase (' || vn_fase || '): ' || sqlerrm);
      end;
      --
    else
      --
      vn_fase := 19;
      --
      -- Gerar log no agendamento devido a data de fechamento
      pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                       ev_mensagem       => 'Desprocessar Integração',
                                       ev_resumo         => 'Período informado para desprocessar a integração de Demais Documentos e Operações - Bloco M EFD Contribuições não ' || 'permitido devido a data de fechamento fiscal ' || to_char(vd_dt_ult_fecha, 'dd/mm/yyyy') || ').',
                                       en_tipo_log       => info_fechamento,
                                       en_referencia_id  => null,
                                       ev_obj_referencia => 'DESPR_INTEGR',
                                       en_empresa_id     => gn_empresa_id);
      --
    end if;
    --
    vn_fase := 20;
    --
    commit;
    --
  end if;
  --
exception
  when others then
    --
    rollback;
    --
    vv_resumo := 'Problemas ao excluir Demais Documentos e Operações - Bloco M EFD Contribuições (id = ' || vn_id || '). Verifique (pk_despr_integr.pkb_despr_m_pc): ' || sqlerrm;
    --
    pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                     ev_mensagem       => 'Desprocessar Integração',
                                     ev_resumo         => vv_resumo,
                                     en_tipo_log       => informacao,
                                     en_referencia_id  => 1,
                                     ev_obj_referencia => 'DESPR_INTEGR',
                                     en_empresa_id     => gn_empresa_id,
                                     en_dm_impressa    => 1);
    --
    raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_m_pc fase (' || vn_fase || '): ' || sqlerrm);
    --
end pkb_despr_m_pc;
--
--------------------------------------------------------------------------------------------------------------------------
-- Procedimento para desprocessar um tipo de integração
------------------------------------------------------------------------------------------
procedure pkb_despr_integr(en_empresa_id       in empresa.id%type,
                           en_usuario_id       in neo_usuario.id%type,
                           en_objintegr_id     in obj_integr.id%type,
                           en_tipoobjintegr_id in tipo_obj_integr.id%type,
                           en_opcao            in number,
                           ed_dt_ini           in date,
                           ed_dt_fin           in date,
                           en_desp_total       in number) is
  --
  vn_fase           number := 0;
  vv_obj_integr     varchar2(10);
  vv_descr          obj_integr.descr%type;
  vn_empresa_id     empresa.id%type;
  vn_loggenerico_id Log_Generico.id%TYPE;
  erro              exception;
  vn_existe_movto   number := 0; -- 0-Não 1-Sim
  --
begin
  --
  vn_fase := 1;
  --
  gv_formato_data := pk_csf.fkg_param_global_csf_form_data;
  --
  -- Busca o código da tabela vv_obj_integr conforme o parâmetro en_objintegr_id.
  begin
    select cd, 
           descr
      into vv_obj_integr, 
           vv_descr
      from obj_integr
     where id = en_objintegr_id;
  exception
    when no_data_found then
      vv_obj_integr := null;
    when others then
      vv_obj_integr := null;
      raise_application_error(-20101, 'Erro na pk_despr_integr.pkb_despr_integr fase (' || vn_fase || '): ' || sqlerrm);
  end;
  --
  vn_fase := 2;
  --
  if trunc(ed_dt_fin) < trunc(ed_dt_ini) then
    --
    pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                     ev_mensagem       => 'Desprocessamento Integração Table/View.',
                                     ev_resumo         => 'Não desprocessado objeto: ' || vv_obj_integr || ' - ' || vv_descr || ', data final menor que data inicial.',
                                     en_tipo_log       => informacao,
                                     en_referencia_id  => 1,
                                     ev_obj_referencia => 'DESPR_INTEGR',
                                     en_empresa_id     => en_empresa_id,
                                     en_dm_impressa    => 1);
    --
    goto sair_despr_integr;
    --
  end if;
  --
  vn_fase := 3;
  --
  -- Recuperando o código do tipo do objeto informado 
  begin
    select toi.cd
      into gv_cd_tipo_obj_integr
      from tipo_obj_integr toi
     where toi.id = en_tipoobjintegr_id;
  exception
    when others then
      gv_cd_tipo_obj_integr := null;
  end;
  --
  vn_fase := 4;
  --
  gn_objintegr_id := en_objintegr_id;
  --
  vn_fase := 5;
  --
  if vv_obj_integr is not null then
    --
    vn_fase := 6;
    --
    gn_multorg_id := pk_csf.fkg_multorg_id_empresa(en_empresa_id => en_empresa_id);
    --
    vn_fase := 7;
    --
    gn_empresa_id := en_empresa_id;
    --
    -- Se o en_opcao for igual a 1 então desprocessa a integração apenas para a empresa logada
    -- e se for igual a 2 desprocessa para todas as empresa.
    if en_opcao = 1 then
      vn_empresa_id := en_empresa_id;
    elsif en_opcao = 2 then
      vn_empresa_id := null;
    end if;
    --
    vn_fase := 8;
    --
    if vv_obj_integr = '1' then
      --
      vn_fase := 9;
      --
      -- Cadastros Gerais
      pkb_despr_cad_geral(en_empresa_id => vn_empresa_id,
                          en_usuario_id => en_usuario_id,
                          ed_dt_ini     => ed_dt_ini,
                          ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '2' then
      --
      vn_fase := 10;
      --
      -- Inventário de estoque de produtos                      --|Não tem tipo|--
      pkb_despr_inventario(en_empresa_id => vn_empresa_id,
                           en_usuario_id => en_usuario_id,
                           ed_dt_ini     => ed_dt_ini,
                           ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '3' then
      --
      vn_fase := 11;
      --
      -- Cupom Fiscal                                           --|Não tem tipo|--
      pkb_despr_cupom_fiscal(en_empresa_id => vn_empresa_id,
                             en_usuario_id => en_usuario_id,
                             ed_dt_ini     => ed_dt_ini,
                             ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '12' then
      --
      vn_fase := 12;
      --
      -- Cupom Fiscal Sat                                          --|Não tem tipo|--
      pkb_despr_cupom_fiscal_sat(en_empresa_id => vn_empresa_id,
                                 en_usuario_id => en_usuario_id,
                                 ed_dt_ini     => ed_dt_ini,
                                 ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '4' then
      --
      vn_fase := 13;
      --
      -- Conhecimento de Transporte                              --|Pronto|--
      pkb_despr_conhec_transp(en_empresa_id => vn_empresa_id,
                              en_usuario_id => en_usuario_id,
                              ed_dt_ini     => ed_dt_ini,
                              ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '5' then
      --
      vn_fase := 14;
      --
      -- Notas Fiscais de Serviços Contínuos (Água, Luz, etc.)  --|Não tem tipo|--
      pkb_despr_nf_serv_cont(en_empresa_id => vn_empresa_id,
                             en_usuario_id => en_usuario_id,
                             ed_dt_ini     => ed_dt_ini,
                             ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '6' then
      --
      vn_fase := 15;
      --
      -- Notas Fiscais Mercantis                                --|Pronto|--
      pkb_despr_nota_fiscal(en_empresa_id => vn_empresa_id,
                            en_usuario_id => en_usuario_id,
                            ed_dt_ini     => ed_dt_ini,
                            ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '7' then
      --
      vn_fase := 16;
      --
      -- Notas Fiscais de Serviços EFD                          --|Pronto|--
      pkb_despr_nf_serv_efd(en_empresa_id => vn_empresa_id,
                            en_usuario_id => en_usuario_id,
                            ed_dt_ini     => ed_dt_ini,
                            ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '8' then
      --
      vn_fase := 17;
      --
      -- C. I. A. P.                                            --|Não tem tipo|--
      pkb_despr_ciap(en_empresa_id => vn_empresa_id,
                     en_usuario_id => en_usuario_id,
                     ed_dt_ini     => ed_dt_ini,
                     ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '9' then
      --
      vn_fase := 18;
      --
      -- Crédito Acumulado de ICMS SP (Ecredac)                 --|Pronto|--
      pkb_despr_ecredac(en_empresa_id => vn_empresa_id,
                        en_usuario_id => en_usuario_id,
                        ed_dt_ini     => ed_dt_ini,
                        ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr in ('27') then
      --
      vn_fase := 19;
      --
      -- Dados Contábil                                         --|Pronto|--
      pkb_despr_dados_secf(en_empresa_id => vn_empresa_id,
                           en_usuario_id => en_usuario_id,
                           ed_dt_ini     => ed_dt_ini,
                           ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr in ('31', '32') then
      --
      vn_fase := 20;
      --
      -- Dados Contábil                                         --|Pronto|--
      pkb_despr_dados_contab(en_empresa_id => vn_empresa_id,
                             en_usuario_id => en_usuario_id,
                             ed_dt_ini     => ed_dt_ini,
                             ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '33' then
      --
      vn_fase := 21;
      --
      if gv_cd_tipo_obj_integr = '1' then
        --
        vn_fase := 21.1;
        --
        -- Produção Diária de Usina
        pkb_despr_pdu(en_empresa_id => vn_empresa_id,
                      en_usuario_id => en_usuario_id,
                      ed_dt_ini     => ed_dt_ini,
                      ed_dt_fin     => ed_dt_fin);
      
      elsif gv_cd_tipo_obj_integr = '2' then
        --
        vn_fase := 21.2;
        --
        -- Verificação de existencia de valores em períodos posteriores ao o que esta sendo apagado.
        -- se existir não deixar apagar. apagar primeiro os movimentos mais novos até chegar a data desejada.
        begin
          select 1
            into vn_existe_movto
            from csf_own.movto_estq m
           where m.dt > add_months(trunc(to_date(ed_dt_ini, 'dd/mm/rrrr'), 'MM'), 1)
             and m.empresa_id in (select e.id
                                    from empresa e
                                   where 1 = 1
                                     and e.multorg_id = nvl(gn_multorg_id, e.multorg_id)
                                     and e.id         = nvl(en_empresa_id, e.id))
             and rownum = 1;
        exception
          when no_data_found then
            vn_existe_movto := 0;
          when others then
            raise_application_error(-20103, 'Erro na pk_despr_integr.pkb_despr_integr fase (' || vn_fase || '): ' || sqlerrm);
        end;
        --
        if vn_existe_movto = 0 then
          --
          -- Verifica se existe movimento posterior ao mês que esta sendo desprocessado. se existir não desprocessa.
          if months_between(trunc(ED_DT_FIN, 'mm'), trunc(ED_DT_INI, 'mm')) = 0 then
            --
            -- Movimento de estoque
            pkb_despr_movto_estq(en_empresa_id => vn_empresa_id,
                                 en_usuario_id => en_usuario_id,
                                 ed_dt_ini     => ed_dt_ini,
                                 ed_dt_fin     => ed_dt_fin);
            vn_fase := 21.3;
            --
            csf_own.pb_sld_movto_estq(en_empresa_id => vn_empresa_id,
                                      ed_dt_ini     => ed_dt_ini,
                                      en_multorg_id => gn_multorg_id);
            --
          else
            --
            vn_fase := 21.4;
            --
            raise erro;
            --
          end if;
          --
        end if;
        --
      elsif gv_cd_tipo_obj_integr = '3' then
        --
        vn_fase := 22;
        --
        -- Análise de conversão ANP
        pkb_despr_analiseconveranp(en_empresa_id => vn_empresa_id,
                                   en_usuario_id => en_usuario_id,
                                   ed_dt_ini     => ed_dt_ini,
                                   ed_dt_fin     => ed_dt_fin);
      end if;
      --
      --
    elsif vv_obj_integr = '36' then
      --
      vn_fase := 23;
      --
      -- Informações de Valores Agregados                       --|Não tem tipo|--
      pkb_despr_iva(en_empresa_id => vn_empresa_id,
                    en_usuario_id => en_usuario_id,
                    ed_dt_ini     => ed_dt_ini,
                    ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '39' then
      --
      vn_fase := 24;
      --
      -- Controle de Creditos Fiscais de ICMS                   --|Não tem tipo|--
      pkb_despr_cf_icms(en_empresa_id => vn_empresa_id,
                        en_usuario_id => en_usuario_id,
                        ed_dt_ini     => ed_dt_ini,
                        ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '42' then
      --
      vn_fase := 25;
      --
      -- Total de Operações com Cartão                          --|Não tem tipo|--
      pkb_despr_tot_op_cart(en_empresa_id => vn_empresa_id,
                            en_usuario_id => en_usuario_id,
                            ed_dt_ini     => ed_dt_ini,
                            ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '45' then
      --
      vn_fase := 26;
      --
      -- Informações da Folha de Pagamento (MANAD)              --|Pronto|--
      pkb_despr_manad(en_empresa_id => vn_empresa_id,
                      en_usuario_id => en_usuario_id,
                      ed_dt_ini     => ed_dt_ini,
                      ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '46' then
      --
      vn_fase := 27;
      --
      -- Pagamento de Impostos no padrÆo para DCTF              --|Pronto|--
      pkb_despr_pgto_imp_ret(en_empresa_id => vn_empresa_id,
                             en_usuario_id => en_usuario_id,
                             ed_dt_ini     => ed_dt_ini,
                             ed_dt_fin     => ed_dt_fin);
      --
      vn_fase := 28;
      --
      -- Procedimento para desprocessar Créditos para DCTF
      pkb_despr_imp_cred_dctf(en_empresa_id => vn_empresa_id,
                              en_usuario_id => en_usuario_id,
                              ed_dt_ini     => ed_dt_ini,
                              ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '47' then
      --
      vn_fase := 29;
      --
      -- Informações da DIRF                                    --|Não tem tipo|--
      pkb_despr_dirf(en_empresa_id => vn_empresa_id,
                     en_usuario_id => en_usuario_id,
                     ed_dt_ini     => ed_dt_ini,
                     ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '48' then
      --
      vn_fase := 30;
      --
      -- Informações do Controle da Produççao e do Estoque      --|Não tem tipo|--
      pkb_despr_contr_prod_estq(en_empresa_id => vn_empresa_id,
                                en_usuario_id => en_usuario_id,
                                ed_dt_ini     => ed_dt_ini,
                                ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '50' then
      --
      vn_fase := 31;
      --
      -- Informações do Bloco F                                 --|Pronto|--
      pkb_despr_ddo(en_empresa_id => vn_empresa_id,
                    en_usuario_id => en_usuario_id,
                    ed_dt_ini     => ed_dt_ini,
                    ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '51' then
      --
      vn_fase := 32;
      --
      -- Informações do Bloco I PC                              --|Não tem tipo|--
      pkb_despr_ibipc(en_empresa_id => vn_empresa_id,
                      en_usuario_id => en_usuario_id,
                      ed_dt_ini     => ed_dt_ini,
                      ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '52' then
      --
      vn_fase := 33;
      --
      -- Informações do DIMOB                                   --|Pronto|--
      pkb_despr_dimob(en_empresa_id => vn_empresa_id,
                      en_usuario_id => en_usuario_id,
                      ed_dt_ini     => ed_dt_ini,
                      ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '53' then
      --
      vn_fase := 34;
      --
      -- Informação de Exportação.
      pkb_despr_infexp(en_empresa_id => vn_empresa_id,
                       en_usuario_id => en_usuario_id,
                       ed_dt_ini     => ed_dt_ini,
                       ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '55' then
      --
      vn_fase := 35;
      --
      -- EFD-REINF - Retenções e Outras Informações Fiscais
      pkb_despr_reinf(en_empresa_id => vn_empresa_id,
                      en_usuario_id => en_usuario_id,
                      ed_dt_ini     => ed_dt_ini,
                      ed_dt_fin     => ed_dt_fin);
      --
    elsif vv_obj_integr = '57' then
      --
      vn_fase := 36;
      --
      -- Demais Documentos e Operações - Bloco M EFD Contribuições
      pkb_despr_m_pc(en_empresa_id => vn_empresa_id,
                     en_usuario_id => en_usuario_id,
                     ed_dt_ini     => ed_dt_ini,
                     ed_dt_fin     => ed_dt_fin);
      --
    else
      --
      vn_fase := 37;
      --
      begin
        pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                         ev_mensagem       => 'Desprocessar Integração',
                                         ev_resumo         => 'Não existe desprocessamento para o código ' || vv_obj_integr || ' - ' || vv_descr,
                                         en_tipo_log       => informacao,
                                         en_referencia_id  => 1,
                                         ev_obj_referencia => 'DESPR_INTEGR',
                                         en_empresa_id     => gn_empresa_id,
                                         en_dm_impressa    => 1);
      exception
        when others then
          null;
      end;
      --
    end if;
    --
    --|Desprocessando objeto em questão das tableas VW's|--
    -- 0 = Desprocessamento total.
    -- <> 0 apenas o deprocessamento do objeto em questão.
    if en_desp_total = 1 then
      --
      declare
        --
        vv_sql varchar2(100);
        --
      begin
        --
        /*            vv_sql := 'begin pk_limpa_open_interf.pkb_limpar(' ||gn_multorg_id||','
           ||gn_objintegr_id||','
           ||en_usuario_id||','
           ||''''||to_char(ed_dt_ini, gv_formato_data)||''''||','
           ||''''||to_char(ed_dt_fin, gv_formato_data)||''''||
        '); end;';*/
        vv_sql := 'begin pk_limpa_open_interf.pkb_limpar_empr(' ||
                  vn_empresa_id || ',' || gn_objintegr_id || ',' ||
                  en_usuario_id || ',' || '''' ||
                  to_char(ed_dt_ini, gv_formato_data) || '''' || ',' || '''' ||
                  to_char(ed_dt_fin, gv_formato_data) || '''' || '); end;';
        --
        execute immediate vv_sql;
        --
      exception
        when others then
          --
          pk_log_generico.pkb_log_generico(sn_loggenerico_id => vn_loggenerico_id,
                                           ev_mensagem       => 'Desprocessamento Integração Table/View.',
                                           ev_resumo         => 'Erro ao desprocessar objeto: ' || vv_obj_integr || ' - ' || vv_descr || ', nas views de integração.',
                                           en_tipo_log       => informacao,
                                           en_referencia_id  => 1,
                                           ev_obj_referencia => 'DESPR_INTEGR',
                                           en_empresa_id     => gn_empresa_id,
                                           en_dm_impressa    => 1);
          --
      end;
      --
    end if;
    --
  end if;
  --
  commit;
  --
  <<sair_despr_integr>>
  --
  null;
  --
exception
  when erro then
    raise_application_error(-20101, 'Para este tipo de integração o período informado deve ser mensal! fase(' || vn_fase || '): ');
  when others then
    raise_application_error(-20102, 'Erro na pk_despr_integr.pkb_despr_integr fase (' || vn_fase || '): ' || sqlerrm);
end pkb_despr_integr;

------------------------------------------------------------------------------------------

end pk_despr_integr;
/
