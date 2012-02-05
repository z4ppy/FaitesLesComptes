// mise en forme des table
jQuery(function() {
    if ($('.organisms .data_table').length != 0) {
        var oTable= $('.organisms .data_table').dataTable({

            "oLanguage": {
                "sUrl": "/frenchdatatable.txt"
            },

            "fnFooterCallback": function ( nRow, aaData, iStart, iEnd, aiDisplay ) {
                /*
             * Calculate the total market share for all browsers in this table (ie inc. outside
             * the pagination)
             */
                var iTotalDebit = 0;
                for ( var i=0 ; i<aaData.length ; i++ )
                {
                    iTotalDebit += stringToFloat(aaData[i][1]);
                }

                /* Calculate the market share for browsers on this page */
                var iPageDebit = 0.0
                for ( var i=iStart ; i<iEnd ; i++ )
                {
                    iPageDebit += stringToFloat(aaData[aiDisplay[i] ][1]);
                }

                var iTotalCredit = 0.0
                for ( var i=0 ; i<aaData.length ; i++ )
                {
                    iTotalCredit += stringToFloat(aaData[i][2]);
                }

                /* Calculate the market share for browsers on this page */
                var iPageCredit = 0.0;
                for ( var i=iStart ; i<iEnd ; i++ )
                {
                    iPageCredit += stringToFloat(aaData[ aiDisplay[i] ][2]);
                }

                /* Modify the footer row to match what we want */
                var nCells = nRow.getElementsByTagName('th');
                nCells[1].innerHTML =  iPageDebit.toFixed(2) +'<br/>'+ iTotalDebit.toFixed(2);
                nCells[2].innerHTML =  iPageCredit.toFixed(2)+'<br/>'+ iTotalCredit.toFixed(2);

            }

        });

        $('td', oTable.fnGetNodes()).hover( function() {
            var iCol = $('td', this.parentNode).index(this) % 3;
            var nTrs = oTable.fnGetNodes();
            $('td:nth-child('+(iCol+1)+')', nTrs).addClass( 'highlighted' );
        }, function() {
            $('td.highlighted', oTable.fnGetNodes()).removeClass('highlighted');
        } );

    }
}); // fin de jQuery application#data_table

function s_to_f(element,index,array){
    return parseFloat(element);
}



// fonction pour tracer les graphes qui apparaissent dans la page organism#show
$(document).ready(function(){
    $.jqplot.config.enablePlugins = true; // semble indispensable pour le highlighter
    
    $('.book').each(function() { // pour chacun des livres

        var id=this.id.match(/\d+$/); // on récupère l'id'
        var s1 =$('#datas_list_' + id).text().split(';').map(s_to_f); // ainsi que les données de l'exercice qui sont dans un champ caché'
        var s2 =$('#previous_datas_list_'+id).text().split(';').map(s_to_f); // les données de l'ex précédent (0 s'il n'y en a pas)'

        // Can specify a custom tick Array.
        // Ticks should match up one for each y value (category) in the series.
        var ticks = $('#months_list_'+id).text().split(';'); // les mois (là aussi vient d'un span caché)
     //   ticks=['J','F','M','A','M','J','J','A','S','O','N','D'];

        var plot2 = $.jqplot('chart_'+id, [s1, s2], {
            // The "seriesDefaults" option is an options object that will
            // be applied to all series in the chart.
            seriesDefaults:{
                renderer:$.jqplot.BarRenderer,
                rendererOptions: {
                    fillToZero: true,
                    barPadding: 0,      // number of pixels between adjacent bars in the same
                    // group (same category or bin).
                    barMargin: 5,      // number of pixels between adjacent groups of bars.
                    barDirection: 'vertical', // vertical or horizontal.
                    barWidth: null,     // width of the bars.  null to calculate automatically.
                    shadowOffset: 2,    // offset from the bar edge to stroke the shadow.
                    shadowDepth: 5,     // nuber of strokes to make for the shadow.
                    shadowAlpha: 0.8 // transparency of the shadow.
                }
            },


            // Custom labels for the series are specified with the "label"
            // option on the series option.  Here a series option object
            // is specified for each series.
            series:[
            {
                label:'2011'
            },

            {
                label:'2012'
            }

            ],
 
//            highlighter: {
//                 sizeAdjust: 10,
//                 tooltipLocation: 'n',
//                 tooltipAxes: 'y',
//                 tooltipFormatString: '%.2f',
//                 useAxesFormatters: true
//           },
   
        
            // Show the legend and put it outside the grid, but inside the
            // plot container, shrinking the grid to accomodate the legend.
            // A value of "outside" would not shrink the grid and allow
            // the legend to overflow the container.
            legend: {
                show: true,
                placement: 'insideGrid',
                location: 'ne',
                legendOptions: {
                   fontSize: '8pt'
                }
               

            },
            axes: {
                // Use a category axis on the x axis and use our custom ticks.
                xaxis: {
                    renderer: $.jqplot.CategoryAxisRenderer,
                    ticks: ticks,
                    tickOptions: {
                    angle: -90,
                    fontSize: '8pt',
                    showMark: true,
                    showGridline: false
                    }
                },
                // Pad the y axis just a little so bars can get close to, but
                // not touch, the grid boundaries.  1.2 is the default padding.
                yaxis: {
                    pad: 1.05,
                    tickOptions: {
                        formatString: '€%d'
                    }
                }
            }
        });
   
  });
});