# -*- encoding : utf-8 -*-

module CashControlsHelper

  def cash_difference(cash_control)
    delta= cash_control.difference.abs
    if ( delta> 0.001)
      "Attention, il subsite un écart de caisse de #{two_decimals(delta)}"
    else
      ''
    end
  end

  def admin_cash_control_submenu_helper(cash, period)
    content_tag :span do
      s=''
      period.list_months.each_with_index do |mois, i|
        u =  content_tag :span do
          link_to_unless_current(mois, admin_organism_cash_cash_controls_path(@organism, cash, "mois"=> i.to_s))
        end
        s += concat(u)
      end
      s
    end

  end

end
