
"use strict";
/*jslint browser: true */
/*global $, jQuery , stringToFloat, $f_numberWithPrecision*/



// mise en forme des tables de lignes
jQuery(function () {
    if ($('.lines_table').length !== 0) {
        $('.lines_table').dataTable({
            "bAutoWidth": false,
            "aoColumnDefs": [
                {
                    "bSortable": false,
                    "aTargets": ['actions' ]
                },
                {
                    "sType": "date-euro",
                    "asSortable": ['asc', 'desc'],
                    "aTargets": ['date-euro'] // les colonnes date au format français ont la classe date-euro
                }],
            "iDisplayLength": 10,
            "aLengthMenu": [[10, 25, 50, -1], [10, 25, 50, "Tous"]],
            "bStateSave": true,
            "fnStateSave": function (oSettings, oData) {
                localStorage.setItem('DataTables_' + window.location.pathname, JSON.stringify(oData));
            },
            "fnStateLoad": function (oSettings) {
                return JSON.parse(localStorage.getItem('DataTables_' + window.location.pathname));
            },
            //            "fnStateSaveParams": function (oSettings, oData) {
            //              oData.oSearch.sSearch = "";
            //            },
            "fnFooterCallback": function (nRow, aaData, iStart, iEnd, aiDisplay) {
                var i = 0,
                    iTotalDebit = 0,
                    iTotalCredit = 0.0,
                    iPageDebit = 0.0,
                    iPageCredit = 0.0,
                    nCells;
                for (i = 0; i < aaData.length; i += 1) {
                    iTotalDebit += stringToFloat(aaData[i][6]);
                }

                /* stringToFloat est défini par JCL dans application.js pour 
                 * pouvoir faire des calculs sur des nombres en format français */
                for (i = iStart; i < iEnd; i += 1) {
                    iPageDebit += stringToFloat(aaData[aiDisplay[i]][6]);
                }
                for (i = 0; i < aaData.length; i += 1) {
                    iTotalCredit += stringToFloat(aaData[i][7]);
                }
                /* Calculate the market share for browsers on this page */
                for (i = iStart; i < iEnd; i += 1) {
                    iPageCredit += stringToFloat(aaData[aiDisplay[i]][7]);
                }

                /* Modify the footer row to match what we want */
                nCells = nRow.getElementsByTagName('th');
                nCells[1].innerHTML =  $f_numberWithPrecision(iPageDebit) + '<br/>' + $f_numberWithPrecision(iTotalDebit);
                nCells[2].innerHTML =  $f_numberWithPrecision(iPageCredit) + '<br/>' + $f_numberWithPrecision(iTotalCredit);
            }
        });
    }
});



// PARTIE POUR LE FORMULAIRE
//
//
//  des fonctions $f_empty et $f_two_decimals sont définies dans application.js
//
// .decimal (toujours dans application js) permet de gérer l'entrée et la sortie des
// champs de classe décimal
//
//
// gère l'affichage des champs banque et caisse;
// La fonction est utilisée pour les in_out_writings que le formulaire soit appelé
// par le controller in_out_writings ou mask_writings. 
// 
//
// evt transmet en original_data la valeur initiale de l'écriture si on est en modification
// d'écriture. Sinon transmet les valeurs par défaut, donc la première banque de la liste
// et la première caisse de la liste.
//
function $f_td_bank_cash(evt) {
    var caisses, banques, income_outcome, payment_mode, encaissement, bank_value, cash_value;
    caisses = $('optgroup[label="Caisses"] option');
    banques = $('optgroup[label="Banques"] option');
    bank_value = evt.data.bank_value;
    cash_value = evt.data.cash_value;
    // pour n'afficher Chèque à l'encaissement que pour les livres de recettes
    if ($('.income_book#entry_lines').length > 0) {
        income_outcome = true;
        encaissement = $('optgroup[label="Chèques à l\'encaissement"] option');
    } else {
        income_outcome = false;
    }

    payment_mode = $(this).val();


    // s'il y a plus d'un élément dans td_bank et si le mode de payemnt 
    // est autre que Espèces alors afficher td_bank et disable td_cash

    switch (payment_mode) {
    case 'Espèces':
        banques.attr('disabled', 'disabled');
        $('#td_check_number').hide();
        caisses.attr('disabled', false);
        banques.attr('selected', false);
        // on masque la zone chèque à l'encaissement si elle existe
        if (income_outcome) {
            encaissement.attr('selected', false).attr('disabled', 'disabled');
        }
        cash_value.attr('selected', 'selected');
        break;
    case 'Chèque':
        caisses.attr('disabled', 'disabled');
        caisses.attr('selected', false);
        if (income_outcome) {
            $('#td_check_number').hide(); // masquage du champ pour  saisir le n° de chèque de la dépenses
            banques.attr('disabled', 'disabled');
            banques.attr('selected', false);
            encaissement.attr('disabled', false);
            encaissement.first().attr('selected', 'selected');
        } else {
            $('#td_check_number').show(); // affichage du champ pour  saisir le n° de chèque de la dépenses
            banques.attr('disabled', false);
            if (banques.size() >= 1) {
                bank_value.attr('selected', 'selected');
            }
        }
        break;
        // autres cas : une recette en banque qui n'est pas un chèque
    default:
        $('#td_check_number').hide(); // masquage du champ n° de chèque
        caisses.attr('disabled', 'disabled'); // désactivation des caisses
        caisses.attr('selected', false);
        banques.attr('disabled', false);
        if (banques.size() >= 1) {
            // on ne sélectionne une banque que si elle ne l'est pas déja par
            // l'enregistrement
            bank_value.attr('selected', 'selected');

        }
        if (income_outcome) {
            encaissement.attr('selected', false);
            encaissement.attr('disabled', 'disabled');
        }
    }
}

// gère l'affichage des champs de saisie de banque et de caisse
// à l'affichage de la page
// on doit avoir pour les recettes :
// lorsque c'est espèces les caisses et rien d'autres
// chèques : le compte chèque à l'encaissement
// banques : les banques
// Pour les dépenses, la partie chèque à l'encaissement n'est pas utile'
jQuery(function () {
    if ($('#entry_lines form').length !== 0) {
        var caisses, banques, bk_value, ca_value, original_value;

        banques = $('optgroup[label="Banques"] option');
        caisses = $('optgroup[label="Caisses"] option');

        // on mémorise les bk_value et ca_value qui serviront de selection
        //
        // soit celle déjà sélectionnée (en mode édition)
        bk_value = $("optgroup[label='Banques'] option[selected='selected']");
        ca_value = $("optgroup[label='Caisses'] option[selected='selected']");

        // soit la première de chaque groupe 
        if (bk_value.length === 0) {
            bk_value = banques.first();
        }
        if (ca_value.length === 0) {
            ca_value = caisses.first();
        }

       // les enregistrer comme valeur originales
        original_value = {
            bank_value: bk_value,
            cash_value: ca_value
        };
        // attacher la fonction $f_td_bank_cash au champ payment_mode 
        // et l'exécuter une première fois'
        $('#entry_lines #in_out_writing_compta_lines_attributes_1_payment_mode').
            change(original_value, $f_td_bank_cash).change();
    }
});

