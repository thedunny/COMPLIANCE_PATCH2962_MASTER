create or replace package csf_own.pk_subapur_icms is

-------------------------------------------------------------------------------------------------------
--
-- Em 09/02/2020 - Allan Magrini  
-- Redmine #75742: Customização ACG.
-- Rotinas Alteradas: pkb_criar_c195_c197, pkb_criar_d195_d197, pkb_criar_1921_1923 e pkb_limpa_c190_d190_1920 adicionado o campo orig 
--                    nos cursores c_nf, c_difal e c_ct a validação nvl(par.orig,999) <> 999 and par.orig = inf.orig
-- Distribuições: 2.9.7 - 2.9.6.2 - 2.9.5.5
--
-- Em 09/12/2020 - Allan Magrini  
-- Redmine #70589: Criação de estruturas e procedures de geração
-- Rotinas Criadas: pkb_criar_c195_c197, pkb_criar_d195_d197, pkb_criar_1921_1923 e pkb_limpa_c190_d190_1920
-- Distribuições: 2.9.6 - 2.9.5.2 - 2.9.4.5
--
-- Em 19/03/2014 - Angela Inês.
-- Redmine #2055 - Especificação do pacote de procedimentos de Geração da Sub-Apuração de ICMS
--
-- Em 04/04/2014 - Angela Inês.
-- Redmine #2055/#2504 - Processo de geração da Sub-Apuração do ICMS.      
-- Redmine #2601 - Criação e correção dos scripts relacionados aos códigos de ocorrências de ajuste.
--
-- Em 13/05/2014 - Angela Inês.
-- Redmine #2738 - Processo de Sub-Apuração de ICMS - D197.
-- Rotinas: fkg_soma_dep_esp_c197_d197, fkg_soma_tot_ded_c197_d197, fkg_soma_credporentr_c197_d197 e fkg_soma_debporsaida_c197_d197.
--
-- Em 23/05/2014 - Angela Inês.
-- Redmine #2910 - Processo de Apuração do Registro 1900. Implementar a seguinte validação:
-- Caso exista registro na tabela "AJUST_SUBAPUR_ICMS_GIA", a soma dos valores deve ser igual ao campo VL_AJ_APUR da tabela AJUST_SUBAPUR_ICMS.
-- Rotina: pk_subapur_icms.pkb_processar_dados.
--
-- Em 07/07/2014 - Angela Inês.
-- Redmine #3261 - Valor de ajuste de nota CTE não foi para a Sub-apuração do ICMS.
-- 1) Acertar as rotinas para que recuperam da tabela de informações fiscais (ct_inf_prov).
-- Rotinas: fkg_soma_dep_esp_c197_d197, fkg_soma_tot_ded_c197_d197, fkg_soma_credporentr_c197_d197 e fkg_soma_debporsaida_c197_d197.
-- 2) Não considerar se o documento fiscal é entrada ou saída (nota_fiscal.dm_ind_emit).
-- Rotinas: fkg_soma_credporentr_c197_d197 e fkg_soma_debporsaida_c197_d197.
--
-- Em 11/06/2015 - Rogério Silva.
-- Redmine #8226 - Processo de Registro de Log em Packages - LOG_GENERICO
--
-- Em 04-17/08/2015 - Angela Inês.
-- Redmine #10117 - Escrituração de documentos fiscais - Processos.
-- Inclusão do novo conceito de recuperação de data dos documentos fiscais para retorno dos registros.
--
-- Em 05/09/2018 - Marcos Ferreira
-- Redmine #46494 - CORREÇÃO SUB APURAÇÃO DE ICMS
-- Solicitação: Alterar o processo de Geração/Processamento:
--              1) Total dos débitos por Saídas e prestações com débito do imposto: Deve buscar os valores do icms das notas fiscais
--              2) Total de Ajuste a débito: Deve buscar os valores lançados em Observações
-- Alterações: funções fkg_soma_debporsaida_c197_d197 e fkg_soma_tot_aj_debitos
--
-- Em 20/09/2018 - Eduardo Linden
-- Redmine #46961 - AJUSTE SUB APURAÇÃO DE ICMS
-- Para o campo total de ajustes estorno de debito , vai receber o processo que gera o valor de total ajuste de debito .
-- O processo para gerar o valor de ajustes de credito é mantido.
-- E o total de ajuste a debito vai receber o valor da mesma origem do ajuste de credito , mas vai ver o parâmetro "outros débitos".
-- Alterações: fkg_soma_tot_aj_debitos e fkg_soma_estorno_deb.
--
-- Em 02/04/2019 - Renan Alves   
-- Redmine #52526 - Sub-apuração não considerando ajuste de débitos na apuração.
-- Como verificado, é necessário recuperar o valor total de ajustes “Estornos de Débitos” da tabela 
-- AJUST_SUBAPUR_ICMS, pois, há situações em que esse valor é informado manualmente.  
-- Rotina: fkg_soma_estorno_deb.
--
-- Em 03/05/2019 - Renan Alves   
-- Redmine #53928 - Valores recuperados na Sub-Apuracao do ICMS.
-- Foram retirados os selects referente a Nota Fiscal e CTE, deixando apenas o select de ajuste de sub-apuração.
-- Rotina: fkg_soma_estorno_deb.
-- Foi alterado o select que retorna às informações da Nota Fiscal.
-- Rotina: fkg_soma_debporsaida_c197_d197
--
-------------------------------------------------------------------------------------------------------

-- Declaração de constantes

   erro_de_validacao  constant number := 1;
   erro_de_sistema    constant number := 2;
   info_subapur_icms  constant number := 33;

-------------------------------------------------------------------------------------------------------

   gt_row_subapur_icms   subapur_icms%rowtype;
   gn_dm_dt_escr_dfepoe  empresa.dm_dt_escr_dfepoe%type;
   --
   gv_cabec_log          log_generico.mensagem%type;
   gv_cabec_log_item     log_generico.mensagem%type;
   gv_mensagem_log       log_generico.mensagem%type;
   gv_resumo_log         log_generico.resumo%type;
   gv_obj_referencia     log_generico.obj_referencia%type default null;
   gn_referencia_id      log_generico.referencia_id%type := null;

-------------------------------------------------------------------------------------------------------

--| Procedimento para calcular a Sub-Apuração do ICMS
procedure pkb_calcular( en_subapuricms_id in subapur_icms.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento para processar/validar as informações da Sub-Apuração de ICMS
procedure pkb_processar( en_subapuricms_id in subapur_icms.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento para desfazer a situação da Sub-Apuração de ICMS
procedure pkb_desfazer( en_subapuricms_id in subapur_icms.id%type );

-------------------------------------------------------------------------------------------------------

end pk_subapur_icms;
/
