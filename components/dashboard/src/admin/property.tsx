/**
 * Copyright (c) 2022 Gitpod GmbH. All rights reserved.
 * Licensed under the GNU Affero General Public License (AGPL).
 * See License-AGPL.txt in the project root for license information.
 */

import { ReactChild } from "react";

export function Property(p: { name: string, children: string | ReactChild, actions?: { label: string, onClick: () => void }[] }) {
    return <div className="ml-3 flex flex-col w-4/12 truncate">
        <div className="text-base text-gray-500 truncate">
            {p.name}
        </div>
        <div className="text-lg text-gray-600 font-semibold truncate">
            {p.children}
        </div>
        {(p.actions || []).map(a =>
            <div className="cursor-pointer text-sm text-blue-400 dark:text-blue-600 hover:text-blue-600 dark:hover:text-blue-400 truncate" onClick={a.onClick}>
                {a.label || ''}
            </div>
        )}
    </div>;
}