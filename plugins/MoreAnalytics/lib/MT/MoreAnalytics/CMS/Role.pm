package MT::MoreAnalytics::CMS::Role;

use strict;

sub on_template_param_edit_role {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $admin = $tmpl->getElementById('administration');
    my $setvar = $tmpl->createElement('setvarblock', {
        name => 'more_analytics_tmpl'
    });
    $setvar->innerHTML(q{
    <__trans_section component="MoreAnalytics">
    <mtapp:setting
       id="more-analytics"
       label="<__trans phrase="More Analytics">">
      <ul class="fixed-width multiple-selection">
      <mt:loop name="loaded_permissions">
      <mt:if name="group" eq="more_analytics">
        <li><label for="<mt:var name="id">"><input id="<mt:var name="id">" type="checkbox" onclick="togglePerms(this, '<mt:var name="children">')" class="<mt:var name="id"> cb" name="permission" value="<mt:var name="id">"<mt:if name="can_do"> checked="checked"</mt:if>> <mt:var name="label" escape="html"></label></li>
      </mt:if>
      </mt:loop>
      </ul>
    </mtapp:setting>
    </__trans_section>
    });
    my $var = $tmpl->createElement('var', {
        name => 'more_analytics_tmpl'
    });

    $tmpl->insertAfter($setvar, $admin);
    $tmpl->insertAfter($var, $setvar);

    1;
}

1;