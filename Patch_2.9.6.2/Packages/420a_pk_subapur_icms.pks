create or replace package csf_own.pk_subapur_icms is

-------------------------------------------------------------------------------------------------------
--
-- Em 09/02/2020 - Allan Magrini  
-- Redmine #75742: Customiza��o ACG.
-- Rotinas Alteradas: pkb_criar_c195_c197, pkb_criar_d195_d197, pkb_criar_1921_1923 e pkb_limpa_c190_d190_1920 adicionado o campo orig 
--                    nos cursores c_nf, c_difal e c_ct a valida��o nvl(par.orig,999) <> 999 and par.orig = inf.orig
-- Distribui��es: 2.9.7 - 2.9.6.2 - 2.9.5.5
--
-- Em 09/12/2020 - Allan Magrini  
-- Redmine #70589: Cria��o de estruturas e procedures de gera��o
-- Rotinas Criadas: pkb_criar_c195_c197, pkb_criar_d195_d197, pkb_criar_1921_1923 e pkb_limpa_c190_d190_1920
-- Distribui��es: 2.9.6 - 2.9.5.2 - 2.9.4.5
--
-- Em 19/03/2014 - Angela In�s.
-- Redmine #2055 - Especifica��o do pacote de procedimentos de Gera��o da Sub-Apura��o de ICMS
--
-- Em 04/04/2014 - Angela In�s.
-- Redmine #2055/#2504 - Processo de gera��o da Sub-Apura��o do ICMS.      
-- Redmine #2601 - Cria��o e corre��o dos scripts relacionados aos c�digos de ocorr�ncias de ajuste.
--
-- Em 13/05/2014 - Angela In�s.
-- Redmine #2738 - Processo de Sub-Apura��o de ICMS - D197.
-- Rotinas: fkg_soma_dep_esp_c197_d197, fkg_soma_tot_ded_c197_d197, fkg_soma_credporentr_c197_d197 e fkg_soma_debporsaida_c197_d197.
--
-- Em 23/05/2014 - Angela In�s.
-- Redmine #2910 - Processo de Apura��o do Registro 1900. Implementar a seguinte valida��o:
-- Caso exista registro na tabela "AJUST_SUBAPUR_ICMS_GIA", a soma dos valores deve ser igual ao campo VL_AJ_APUR da tabela AJUST_SUBAPUR_ICMS.
-- Rotina: pk_subapur_icms.pkb_processar_dados.
--
-- Em 07/07/2014 - Angela In�s.
-- Redmine #3261 - Valor de ajuste de nota CTE n�o foi para a Sub-apura��o do ICMS.
-- 1) Acertar as rotinas para que recuperam da tabela de informa��es fiscais (ct_inf_prov).
-- Rotinas: fkg_soma_dep_esp_c197_d197, fkg_soma_tot_ded_c197_d197, fkg_soma_credporentr_c197_d197 e fkg_soma_debporsaida_c197_d197.
-- 2) N�o considerar se o documento fiscal � entrada ou sa�da (nota_fiscal.dm_ind_emit).
-- Rotinas: fkg_soma_credporentr_c197_d197 e fkg_soma_debporsaida_c197_d197.
--
-- Em 11/06/2015 - Rog�rio Silva.
-- Redmine #8226 - Processo de Registro de Log em Packages - LOG_GENERICO
--
-- Em 04-17/08/2015 - Angela In�s.
-- Redmine #10117 - Escritura��o de documentos fiscais - Processos.
-- Inclus�o do novo conceito de recupera��o de data dos documentos fiscais para retorno dos registros.
--
-- Em 05/09/2018 - Marcos Ferreira
-- Redmine #46494 - CORRE��O SUB APURA��O DE ICMS
-- Solicita��o: Alterar o processo de Gera��o/Processamento:
--              1) Total dos d�bitos por Sa�das e presta��es com d�bito do imposto: Deve buscar os valores do icms das notas fiscais
--              2) Total de Ajuste a d�bito: Deve buscar os valores lan�ados em Observa��es
-- Altera��es: fun��es fkg_soma_debporsaida_c197_d197 e fkg_soma_tot_aj_debitos
--
-- Em 20/09/2018 - Eduardo Linden
-- Redmine #46961 - AJUSTE SUB APURA��O DE ICMS
-- Para o campo total de ajustes estorno de debito , vai receber o processo que gera o valor de total ajuste de debito .
-- O processo para gerar o valor de ajustes de credito � mantido.
-- E o total de ajuste a debito vai receber o valor da mesma origem do ajuste de credito , mas vai ver o par�metro "outros d�bitos".
-- Altera��es: fkg_soma_tot_aj_debitos e fkg_soma_estorno_deb.
--
-- Em 02/04/2019 - Renan Alves   
-- Redmine #52526 - Sub-apura��o n�o considerando ajuste de d�bitos na apura��o.
-- Como verificado, � necess�rio recuperar o valor total de ajustes �Estornos de D�bitos� da tabela 
-- AJUST_SUBAPUR_ICMS, pois, h� situa��es em que esse valor � informado manualmente.  
-- Rotina: fkg_soma_estorno_deb.
--
-- Em 03/05/2019 - Renan Alves   
-- Redmine #53928 - Valores recuperados na Sub-Apuracao do ICMS.
-- Foram retirados os selects referente a Nota Fiscal e CTE, deixando apenas o select de ajuste de sub-apura��o.
-- Rotina: fkg_soma_estorno_deb.
-- Foi alterado o select que retorna �s informa��es da Nota Fiscal.
-- Rotina: fkg_soma_debporsaida_c197_d197
--
-------------------------------------------------------------------------------------------------------

-- Declara��o de constantes

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

--| Procedimento para calcular a Sub-Apura��o do ICMS
procedure pkb_calcular( en_subapuricms_id in subapur_icms.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento para processar/validar as informa��es da Sub-Apura��o de ICMS
procedure pkb_processar( en_subapuricms_id in subapur_icms.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento para desfazer a situa��o da Sub-Apura��o de ICMS
procedure pkb_desfazer( en_subapuricms_id in subapur_icms.id%type );

-------------------------------------------------------------------------------------------------------

end pk_subapur_icms;
/
